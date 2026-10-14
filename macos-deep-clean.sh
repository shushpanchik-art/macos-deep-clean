#!/bin/bash
# macOS Deep Clean Script
# Глубокая очистка системы: кеши, сироты, временные файлы
# Основано на опыте очистки от 14.10.2026

VERSION="1.0.0"
LOG_FILE="$HOME/.macos-cleanup.log"
REPORT_FILE="/tmp/cleanup-report-$(date +%Y%m%d-%H%M%S).txt"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Счетчики
TOTAL_FREED=0
ITEMS_CLEANED=0

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

print_header() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}   $1${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

get_size() {
    if [ -e "$1" ]; then
        du -sh "$1" 2>/dev/null | cut -f1
    else
        echo "0B"
    fi
}

get_size_bytes() {
    if [ -e "$1" ]; then
        du -sk "$1" 2>/dev/null | cut -f1
    else
        echo "0"
    fi
}

cleanup_caches() {
    print_header "🗑️  ОЧИСТКА КЕШЕЙ"

    local cleaned=0

    # User caches
    if [ -d "$HOME/Library/Caches" ]; then
        echo -n "Анализ пользовательских кешей... "

        # Большие кеши приложений (>100MB)
        for cache_dir in "$HOME/Library/Caches"/*; do
            if [ -d "$cache_dir" ]; then
                size_kb=$(get_size_bytes "$cache_dir")
                if [ "$size_kb" -gt 102400 ]; then  # >100MB
                    app_name=$(basename "$cache_dir")
                    size=$(get_size "$cache_dir")

                    # Пропускаем критичные кеши
                    if [[ "$app_name" =~ ^(com.apple.dyld|com.apple.Metal|CloudKit)$ ]]; then
                        continue
                    fi

                    rm -rf "$cache_dir" 2>/dev/null && {
                        print_success "Удален кеш: $app_name ($size)"
                        cleaned=$((cleaned + size_kb))
                        ITEMS_CLEANED=$((ITEMS_CLEANED + 1))
                    }
                fi
            fi
        done
        echo "Готово"
    fi

    # System caches (требует sudo)
    if command -v sudo &> /dev/null; then
        echo -n "Очистка системных кешей... "
        sudo rm -rf /Library/Caches/* 2>/dev/null && print_success "Системные кеши очищены"
        sudo rm -rf /System/Library/Caches/* 2>/dev/null
        echo "Готово"
    fi

    # DNS cache
    echo -n "Очистка DNS кеша... "
    sudo dscacheutil -flushcache 2>/dev/null && \
    sudo killall -HUP mDNSResponder 2>/dev/null && \
    print_success "DNS кеш очищен"

    TOTAL_FREED=$((TOTAL_FREED + cleaned))
    echo ""
}

cleanup_logs() {
    print_header "📝 ОЧИСТКА ЛОГОВ"

    local cleaned=0

    # User logs (старше 7 дней)
    if [ -d "$HOME/Library/Logs" ]; then
        echo -n "Удаление старых логов пользователя... "
        find "$HOME/Library/Logs" -type f -mtime +7 -delete 2>/dev/null
        print_success "Старые логи удалены"
    fi

    # System logs (требует sudo)
    echo -n "Очистка системных логов... "
    sudo rm -rf /var/log/asl/*.asl 2>/dev/null
    sudo rm -rf /Library/Logs/DiagnosticReports/* 2>/dev/null
    print_success "Системные логи очищены"

    echo ""
}

find_orphans() {
    print_header "🔍 ПОИСК СИРОТ (удаленные приложения)"

    echo "Анализ установленных приложений..."

    # Получить список установленных приложений
    local installed_apps=$(find /Applications ~/Applications -maxdepth 1 -name "*.app" -type d 2>/dev/null | \
        xargs -I {} basename {} .app | sort -u)

    echo "Найдено приложений: $(echo "$installed_apps" | wc -l)"
    echo ""

    local orphans_found=0
    local orphans_size=0

    # Проверка Application Support
    echo "Проверка ~/Library/Application Support..."
    if [ -d "$HOME/Library/Application Support" ]; then
        for app_dir in "$HOME/Library/Application Support"/*; do
            if [ -d "$app_dir" ]; then
                app_name=$(basename "$app_dir")

                # Пропускаем системные папки
                if [[ "$app_name" =~ ^(com.apple\.|Adobe|Google|Microsoft|CloudDocs).*$ ]]; then
                    continue
                fi

                # Проверяем есть ли приложение
                if ! echo "$installed_apps" | grep -qi "$app_name"; then
                    size=$(get_size "$app_dir")
                    size_kb=$(get_size_bytes "$app_dir")

                    # Показываем только если >10MB
                    if [ "$size_kb" -gt 10240 ]; then
                        echo -e "  ${YELLOW}СИРОТА:${NC} $app_name ($size)"
                        orphans_found=$((orphans_found + 1))
                        orphans_size=$((orphans_size + size_kb))

                        # Удаляем
                        rm -rf "$app_dir" 2>/dev/null && {
                            print_success "  Удалено: $app_dir"
                            ITEMS_CLEANED=$((ITEMS_CLEANED + 1))
                            TOTAL_FREED=$((TOTAL_FREED + size_kb))
                        }
                    fi
                fi
            fi
        done
    fi

    # Проверка Group Containers
    echo ""
    echo "Проверка ~/Library/Group Containers..."
    if [ -d "$HOME/Library/Group Containers" ]; then
        for container in "$HOME/Library/Group Containers"/*; do
            if [ -d "$container" ]; then
                container_name=$(basename "$container")

                # Пропускаем Apple контейнеры
                if [[ "$container_name" =~ ^[A-Z0-9]+\.com\.apple\. ]]; then
                    continue
                fi

                # Проверяем размер
                size_kb=$(get_size_bytes "$container")
                if [ "$size_kb" -gt 10240 ]; then  # >10MB
                    size=$(get_size "$container")

                    # Показываем подозрительные
                    echo -e "  ${YELLOW}Проверьте:${NC} $container_name ($size)"
                fi
            fi
        done
    fi

    # Проверка Preferences (orphaned plists)
    echo ""
    echo "Проверка ~/Library/Preferences..."
    if [ -d "$HOME/Library/Preferences" ]; then
        local prefs_removed=0
        for pref_file in "$HOME/Library/Preferences"/*.plist; do
            if [ -f "$pref_file" ]; then
                pref_name=$(basename "$pref_file" .plist)

                # Пропускаем системные
                if [[ "$pref_name" =~ ^com.apple\. ]]; then
                    continue
                fi

                # Проверяем есть ли приложение
                if ! echo "$installed_apps" | grep -qi "${pref_name#com.}"; then
                    # Мелкие файлы удаляем сразу
                    rm -f "$pref_file" 2>/dev/null && {
                        prefs_removed=$((prefs_removed + 1))
                    }
                fi
            fi
        done

        if [ "$prefs_removed" -gt 0 ]; then
            print_success "Удалено preferences файлов: $prefs_removed"
            ITEMS_CLEANED=$((ITEMS_CLEANED + prefs_removed))
        fi
    fi

    echo ""
    if [ "$orphans_found" -gt 0 ]; then
        print_info "Найдено и удалено сирот: $orphans_found (~$((orphans_size / 1024))MB)"
    else
        print_success "Сироты не найдены"
    fi

    echo ""
}

cleanup_downloads() {
    print_header "📥 ОЧИСТКА DOWNLOADS"

    if [ ! -d "$HOME/Downloads" ]; then
        print_warning "Папка Downloads не найдена"
        return
    fi

    echo "Анализ папки Downloads..."

    local cleaned=0
    local items=0

    # Удаляем .dmg и .pkg старше 30 дней
    echo -n "Удаление старых установщиков (.dmg, .pkg)... "
    find "$HOME/Downloads" -type f \( -name "*.dmg" -o -name "*.pkg" \) -mtime +30 -delete 2>/dev/null
    print_success "Готово"

    # Показываем большие файлы для ручной проверки
    echo ""
    echo "Большие файлы в Downloads (>100MB):"
    find "$HOME/Downloads" -type f -size +100M -exec du -h {} \; 2>/dev/null | \
        sort -rh | head -10 | while read size file; do
        echo "  $size - $(basename "$file")"
    done

    echo ""
}

cleanup_trash() {
    print_header "🗑️  ОЧИСТКА КОРЗИНЫ"

    if [ -d "$HOME/.Trash" ]; then
        local size=$(get_size "$HOME/.Trash")
        local size_kb=$(get_size_bytes "$HOME/.Trash")

        if [ "$size_kb" -gt 0 ]; then
            echo "Размер корзины: $size"
            rm -rf "$HOME/.Trash"/* 2>/dev/null && {
                print_success "Корзина очищена"
                TOTAL_FREED=$((TOTAL_FREED + size_kb))
                ITEMS_CLEANED=$((ITEMS_CLEANED + 1))
            }
        else
            print_info "Корзина пуста"
        fi
    fi

    echo ""
}

cleanup_xcode() {
    print_header "🔨 ОЧИСТКА XCODE (если установлен)"

    if [ ! -d "$HOME/Library/Developer/Xcode" ]; then
        print_info "Xcode не установлен, пропускаем"
        echo ""
        return
    fi

    local cleaned=0

    # DerivedData
    if [ -d "$HOME/Library/Developer/Xcode/DerivedData" ]; then
        local size_kb=$(get_size_bytes "$HOME/Library/Developer/Xcode/DerivedData")
        local size=$(get_size "$HOME/Library/Developer/Xcode/DerivedData")

        if [ "$size_kb" -gt 0 ]; then
            echo "DerivedData: $size"
            rm -rf "$HOME/Library/Developer/Xcode/DerivedData"/* 2>/dev/null && {
                print_success "DerivedData очищен"
                cleaned=$((cleaned + size_kb))
            }
        fi
    fi

    # Archives (старые)
    if [ -d "$HOME/Library/Developer/Xcode/Archives" ]; then
        echo -n "Удаление старых Archives (>90 дней)... "
        find "$HOME/Library/Developer/Xcode/Archives" -type d -mtime +90 -delete 2>/dev/null
        print_success "Готово"
    fi

    # iOS DeviceSupport
    if [ -d "$HOME/Library/Developer/Xcode/iOS DeviceSupport" ]; then
        echo -n "Очистка старых iOS DeviceSupport... "
        # Оставляем только последние 3 версии
        ls -t "$HOME/Library/Developer/Xcode/iOS DeviceSupport" | tail -n +4 | \
            xargs -I {} rm -rf "$HOME/Library/Developer/Xcode/iOS DeviceSupport/{}" 2>/dev/null
        print_success "Готово"
    fi

    TOTAL_FREED=$((TOTAL_FREED + cleaned))
    echo ""
}

cleanup_brew() {
    print_header "🍺 ОЧИСТКА HOMEBREW"

    if ! command -v brew &> /dev/null; then
        print_info "Homebrew не установлен, пропускаем"
        echo ""
        return
    fi

    echo -n "Очистка старых версий формул... "
    brew cleanup -s 2>/dev/null && print_success "Готово"

    echo -n "Удаление кешей... "
    rm -rf "$(brew --cache)" 2>/dev/null && print_success "Готово"

    echo -n "Проверка и восстановление... "
    brew doctor 2>&1 | grep -q "ready to brew" && print_success "Homebrew в порядке"

    echo ""
}

memory_purge() {
    print_header "💾 ОЧИСТКА ПАМЯТИ"

    echo "Память ДО очистки:"
    vm_stat | head -6 | grep -E "(Pages free|Pages inactive|Pages purgeable)"

    echo ""
    echo -n "Запуск memory purge (может занять 30-60 сек)... "
    sudo purge 2>/dev/null && {
        print_success "Memory purge выполнен"
        echo ""
        echo "Память ПОСЛЕ очистки:"
        vm_stat | head -6 | grep -E "(Pages free|Pages inactive|Pages purgeable)"
    }

    echo ""
}

generate_report() {
    print_header "📊 ОТЧЕТ О ОЧИСТКЕ"

    local freed_mb=$((TOTAL_FREED / 1024))
    local freed_gb=$(awk "BEGIN {printf \"%.2f\", $freed_mb/1024}")

    # Показываем статистику диска
    echo "Состояние диска:"
    df -h / | grep -v Filesystem
    echo ""

    echo -e "${GREEN}✅ РЕЗУЛЬТАТЫ ОЧИСТКИ:${NC}"
    echo "• Освобождено: ~${freed_gb} GB"
    echo "• Элементов удалено: $ITEMS_CLEANED"
    echo ""

    # Сохраняем отчет
    {
        echo "════════════════════════════════════════════════════"
        echo "  macOS Deep Clean Report"
        echo "  Дата: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "════════════════════════════════════════════════════"
        echo ""
        echo "Освобождено: ~${freed_gb} GB"
        echo "Элементов удалено: $ITEMS_CLEANED"
        echo ""
        echo "Состояние диска:"
        df -h /
    } > "$REPORT_FILE"

    echo -e "${CYAN}Отчет сохранен: $REPORT_FILE${NC}"
    echo ""
}

show_help() {
    cat << EOF
macOS Deep Clean Script v${VERSION}

Использование: clean [ОПЦИИ]

Опции:
  --quick       Быстрая очистка (только кеши и корзина)
  --deep        Глубокая очистка (все включая сироты) [по умолчанию]
  --purge       Только memory purge
  --orphans     Только поиск сирот
  --help        Показать эту справку

Примеры:
  clean              # Полная очистка
  clean --quick      # Быстрая очистка
  clean --orphans    # Только поиск сирот

EOF
}

main() {
    clear

    print_header "🧹 macOS DEEP CLEAN v${VERSION}"

    echo -e "${CYAN}Глубокая очистка системы${NC}"
    echo -e "Дата: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""

    log "=== Начало очистки ==="

    local mode="${1:-deep}"

    case "$mode" in
        --help)
            show_help
            exit 0
            ;;
        --quick)
            cleanup_caches
            cleanup_trash
            memory_purge
            ;;
        --purge)
            memory_purge
            ;;
        --orphans)
            find_orphans
            ;;
        --deep|*)
            cleanup_caches
            cleanup_logs
            find_orphans
            cleanup_downloads
            cleanup_trash
            cleanup_xcode
            cleanup_brew
            memory_purge
            ;;
    esac

    generate_report

    log "=== Очистка завершена ==="

    print_header "✅ ГОТОВО"
    echo -e "${GREEN}Очистка завершена успешно!${NC}"
    echo ""
}

# Запуск
main "$@"
