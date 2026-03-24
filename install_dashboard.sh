#!/bin/sh

# Конфигурационные параметры
REMOTE_BANNER_SOURCE="https://raw.githubusercontent.com/LostGit77/ENTWARE-Dashboard/refs/heads/main/entware_dashboard.sh"
INSTALL_LOCATION="/opt/etc/entware_dashboard.sh"
USER_PROFILE="$HOME/.profile"

# Главное меню действий
show_menu() {
    echo ""
    echo "*ENTWARE Router Management*"
    echo ""
    echo "1 — Установить"
    echo "2 — Удалить"
    echo "3 — Обновить"
    echo "0 — Выход"
}

# Процесс установки
perform_installation() {
    echo "Запуск инсталляции..."
    
    # Обновление и установка зависимостей
    opkg update
    opkg install curl wget wget-ssl coreutils-df procps-ng-free procps-ng-uptime
    
    # Загрузка скрипта баннера
    curl -fsSL -o "$INSTALL_LOCATION" "$REMOTE_BANNER_SOURCE"
    
    # Настройка прав доступа
    chmod +x "$INSTALL_LOCATION"
    
    # Добавление в профиль пользователя
    if ! grep -qxF "$INSTALL_LOCATION" "$USER_PROFILE"; then
        echo "$INSTALL_LOCATION" >> "$USER_PROFILE"
    fi
    
    echo ""
    echo "Инсталляция успешно завершена"
    echo "Пожалуйста, переподключитесь к терминалу"
}

# Процесс удаления
perform_removal() {
    echo "Запуск деинсталляции..."
    
    # Удаление основного файла
    rm -f "$INSTALL_LOCATION"
    
    # Очистка символических ссылок
    echo "  → Выполняется очистка символических ссылок:"
    for command_name in install update remove manager banner link help; do
        link_path="/opt/bin/$command_name"
        if [ -L "$link_path" ] || [ -e "$link_path" ]; then
            echo "    - $link_path"
            rm -f "$link_path"
        fi
    done
    
    # Исключение строки из профайла
    sed -i "\|${INSTALL_LOCATION}|d" "$USER_PROFILE"
    
    echo "Деинсталляция завершена."
}

    # Процесс обновления
    perform_update() {
        echo "Запуск обновления..."
        perform_removal
        perform_installation
    }

# Основной цикл обработки
printf "\033[2J\033[H" #очистка перед первым запуском
main_loop() {
    while :; do
        show_menu
        printf "Сделайте выбор: "
        read -r user_choice

        case "$user_choice" in
            1)
                perform_installation
                ;;
            2)
                perform_removal
                ;;
            3)
                perform_update
                ;;
            0)
                echo "Программа завершена."
                return 0
                ;;
            *)
                echo "Ошибка ввода, повторите попытку."
                ;;
        esac
    done
}

# Запуск основного цикла
main_loop
