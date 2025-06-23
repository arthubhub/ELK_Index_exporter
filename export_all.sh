#!/bin/bash

ELASTICSEARCH_HOST="" # -> "192.168.1.1:9200"
USERNAME="" # -> "elastic"
PASSWORD="" # -> "yourpass"
INDEX_LIST_FILE="index_list.txt"
OUTPUT_DIR="./exports"
BATCH_SIZE=5000
SCROLL_TIMEOUT="5m"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

check_prerequisites() {
    log "Vérification des prérequis..."
    
    if ! command -v curl &> /dev/null; then
        error "curl n'est pas installé"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        warning "jq n'est pas installé. Recommandé pour un meilleur formatage JSON."
    fi
    
    if [[ ! -f "$INDEX_LIST_FILE" ]]; then
        error "Le fichier $INDEX_LIST_FILE n'existe pas"
        exit 1
    fi
    
    if ! curl -s -u "$USERNAME:$PASSWORD" "$ELASTICSEARCH_HOST" &> /dev/null; then
        error "Impossible de se connecter à Elasticsearch sur $ELASTICSEARCH_HOST"
        exit 1
    fi
    
    success "Prérequis vérifiés"
}

create_output_dir() {
    if [[ ! -d "$OUTPUT_DIR" ]]; then
        mkdir -p "$OUTPUT_DIR"
        log "Répertoire de sortie créé : $OUTPUT_DIR"
    fi
}

get_document_count() {
    local index_name="$1"
    local count=$(curl -s -u "$USERNAME:$PASSWORD" \
        "$ELASTICSEARCH_HOST/$index_name/_count" | \
        grep -o '"count":[0-9]*' | cut -d':' -f2)
    echo "$count"
}

export_index() {
    local index_name="$1"
    local output_file="$OUTPUT_DIR/${index_name}.json"
    local temp_file="$OUTPUT_DIR/${index_name}.tmp"
    local scroll_id=""
    local total_exported=0
    local doc_count=$(get_document_count "$index_name")
    
    log "Début de l'export de l'index : $index_name"
    log "Nombre total de documents : $doc_count"
    
    [[ -f "$output_file" ]] && rm "$output_file"
    [[ -f "$temp_file" ]] && rm "$temp_file"
    
    local initial_response=$(curl -s -u "$USERNAME:$PASSWORD" \
        -X GET "$ELASTICSEARCH_HOST/$index_name/_search?scroll=$SCROLL_TIMEOUT" \
        -H 'Content-Type: application/json' \
        -d "{
            \"size\": $BATCH_SIZE,
            \"query\": {
                \"match_all\": {}
            }
        }")
    
    if echo "$initial_response" | grep -q '"error"'; then
        error "Erreur lors de l'export de $index_name:"
        echo "$initial_response" | jq -r '.error.reason' 2>/dev/null || echo "$initial_response"
        return 1
    fi
    
    scroll_id=$(echo "$initial_response" | grep -o '"_scroll_id":"[^"]*"' | cut -d'"' -f4)
    
    echo "$initial_response" | jq -c '.hits.hits[]' >> "$temp_file" 2>/dev/null || \
    echo "$initial_response" | grep -o '"hits":\[.*\]' | sed 's/"hits":\[//;s/\]$//' | \
    sed 's/},{/}\n{/g' >> "$temp_file"
    
    local batch_count=$(echo "$initial_response" | grep -o '"hits":\[.*\]' | grep -o '{"_index"' | wc -l)
    total_exported=$batch_count
    
    log "Premier batch : $batch_count documents exportés"
    
    while [[ -n "$scroll_id" ]] && [[ $batch_count -gt 0 ]]; do
        local scroll_response=$(curl -s -u "$USERNAME:$PASSWORD" \
            -X GET "$ELASTICSEARCH_HOST/_search/scroll" \
            -H 'Content-Type: application/json' \
            -d "{
                \"scroll\": \"$SCROLL_TIMEOUT\",
                \"scroll_id\": \"$scroll_id\"
            }")
        
        if echo "$scroll_response" | grep -q '"error"'; then
            error "Erreur lors du scroll pour $index_name"
            break
        fi
        
        echo "$scroll_response" | jq -c '.hits.hits[]' >> "$temp_file" 2>/dev/null || \
        echo "$scroll_response" | grep -o '"hits":\[.*\]' | sed 's/"hits":\[//;s/\]$//' | \
        sed 's/},{/}\n{/g' >> "$temp_file"
        
        batch_count=$(echo "$scroll_response" | grep -o '"hits":\[.*\]' | grep -o '{"_index"' | wc -l)
        total_exported=$((total_exported + batch_count))
        
        scroll_id=$(echo "$scroll_response" | grep -o '"_scroll_id":"[^"]*"' | cut -d'"' -f4)
        
        log "Batch : $batch_count documents | Total exporté : $total_exported/$doc_count"
        
        sleep 0.1
    done
    if [[ -n "$scroll_id" ]]; then
        curl -s -u "$USERNAME:$PASSWORD" \
            -X DELETE "$ELASTICSEARCH_HOST/_search/scroll" \
            -H 'Content-Type: application/json' \
            -d "{\"scroll_id\": [\"$scroll_id\"]}" > /dev/null
    fi
    if [[ -f "$temp_file" ]]; then
        mv "$temp_file" "$output_file"
        success "Index $index_name exporté : $total_exported documents dans $output_file"
        
        # Compression du fichier (optionnel)
        if command -v gzip &> /dev/null; then
            gzip "$output_file"
            success "Fichier compressé : ${output_file}.gz"
        fi
    else
        error "Aucun document exporté pour l'index $index_name"
        return 1
    fi
}

main() {
    log "Début de l'export des index Elasticsearch"
    
    check_prerequisites
    create_output_dir
    
    local total_indexes=0
    local successful_exports=0
    local failed_exports=0
    
    while IFS= read -r index_name; do
        # Ignorer les lignes vides et les commentaires
        [[ -z "$index_name" || "$index_name" =~ ^[[:space:]]*# ]] && continue
        
        total_indexes=$((total_indexes + 1))
        
        log "----------------------------------------"
        if export_index "$index_name"; then
            successful_exports=$((successful_exports + 1))
        else
            failed_exports=$((failed_exports + 1))
        fi
        
    done < "$INDEX_LIST_FILE"
    
    log "========================================"
    log "Export terminé !"
    log "Total des index : $total_indexes"
    success "Exports réussis : $successful_exports"
    [[ $failed_exports -gt 0 ]] && error "Exports échoués : $failed_exports"
    log "Fichiers de sortie dans : $OUTPUT_DIR"
    
    if command -v du &> /dev/null; then
        local total_size=$(du -sh "$OUTPUT_DIR" | cut -f1)
        log "Taille totale des exports : $total_size"
    fi
}

cleanup() {
    log "Arrêt du script en cours..."
    # Nettoyage des fichiers temporaires
    find "$OUTPUT_DIR" -name "*.tmp" -delete 2>/dev/null
    exit 1
}

trap cleanup SIGINT SIGTERM

main "$@"
