#!/bin/sh

# ===== Автоматическое создание симлинков =====
SCRIPT_PATH="/opt/etc/entware_dashboard.sh"
INSTALL_PATH="/opt/bin/install"
UPDATE_PATH="/opt/bin/update"
REMOVE_PATH="/opt/bin/remove"
MANAGER_PATH="/opt/bin/manager"		
BANNER_PATH="/opt/bin/banner"
LINK_PATH="/opt/bin/link"
HELP_PATH="/opt/bin/help"

# Создаем симлинки ТОЛЬКО если их нет
if [ ! -L "$INSTALL_PATH" ] && [ ! -e "$INSTALL_PATH" ]; then
  ln -s "$SCRIPT_PATH" "$INSTALL_PATH" 2>/dev/null
fi

if [ ! -L "$UPDATE_PATH" ] && [ ! -e "$UPDATE_PATH" ]; then
  ln -s "$SCRIPT_PATH" "$UPDATE_PATH" 2>/dev/null
fi

if [ ! -L "$REMOVE_PATH" ] && [ ! -e "$REMOVE_PATH" ]; then
  ln -s "$SCRIPT_PATH" "$REMOVE_PATH" 2>/dev/null
fi

if [ ! -L "$MANAGER_PATH" ] && [ ! -e "$MANAGER_PATH" ]; then
  ln -s "$SCRIPT_PATH" "$MANAGER_PATH" 2>/dev/null
fi

if [ ! -L "$BANNER_PATH" ] && [ ! -e "$BANNER_PATH" ]; then
  ln -s "$SCRIPT_PATH" "$BANNER_PATH" 2>/dev/null
fi

if [ ! -L "$LINK_PATH" ] && [ ! -e "$LINK_PATH" ]; then
  ln -s "$SCRIPT_PATH" "$LINK_PATH" 2>/dev/null
fi

if [ ! -L "$HELP_PATH" ] && [ ! -e "$HELP_PATH" ]; then
  ln -s "$SCRIPT_PATH" "$HELP_PATH" 2>/dev/null
fi

# ===== УНИВЕРСАЛЬНАЯ ФУНКЦИЯ ДЛЯ ПОЛУЧЕНИЯ ROUTER_IP =====
get_router_ip() {
  # Получаем IP через br0 (главный LAN-мост Keenetic)
  ip -4 addr show dev br0 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1 || 
  # Fallback на стандартный адрес
  echo "192.168.1.1"
}

# ===== Проверка установленных сервисов =====
is_installed() {
  local package="$1"
  opkg list-installed | grep -q "^${package} "
  return $?
}

# ===== Функция подтверждения действий =====
confirm() {
  prompt="$1"
  default="$2"

  if [ -n "$default" ]; then
    printf "%s [Default %s]: " "$prompt" "$default"
  else
    printf "%s [y/n]: " "$prompt"
  fi

  read temp

  if [ -z "$temp" ] && [ -n "$default" ]; then
    temp="$default"
  fi

  case "$temp" in
    y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

# ===== Если запущен как install или update =====
CMD_NAME=$(basename "$0")

case "$CMD_NAME" in
  "install"|"custom-install")
    # Обработка установки сервисов
    if [ -z "$1" ]; then
	  echo "❗ Укажите сервис для установки"
	  echo "👉 Использование: install <сервис>"
	  echo "📦 Доступные сервисы: neofit, x-ui, hrneo, magitrickle, awg-manager, nfqws2, b4"
	  echo "💡 Пример: install neofit"
      exit 1
    fi
    
    SERVICE="$1"
    # Получаем IP-адрес роутера через нашу функцию
	ROUTER_IP="$(get_router_ip)"
	
   install_service() {
  case "$1" in
    neofit)
      if is_installed "neofit"; then
        echo -e "\n\033[1;33m⚠️  neofit уже установлен!\033[0m"
        echo -e "\033[1;37m   Используйте команду 'banner' чтобы посмотреть статус сервиса.\033[0m"
        exit 0
      fi
      
      if ! confirm "Вы хотите установить neofit?" "y"; then
        echo -e "\n\033[1;33m⚠️  Установка отменена!\033[0m"
        exit 0
      fi
      
      echo -e "\033[1;32m🚀 Установка neofit...\033[0m"
      
      # 1. Обновляем список пакетов
      echo -e "\033[1;33m→ Обновление списка пакетов...\033[0m"
      if ! opkg update >/dev/null 2>&1; then
        echo -e "\n\033[1;31m❌ Не удалось обновить список пакетов!\033[0m"
        exit 1
      fi
      
      # 2. Устанавливаем curl при необходимости
      if ! command -v curl >/dev/null 2>&1; then
        echo -e "\033[1;33m→ Установка curl...\033[0m"
        if ! opkg install curl >/dev/null 2>&1; then
          echo -e "\n\033[1;31m❌ Не удалось установить curl!\033[0m"
          exit 1
        fi
      fi
      
      # 3. Запускаем установочный скрипт
      echo -e "\033[1;33m→ Запуск скрипта установки...\033[0m"
      if ! curl -Ls "http://www.pegakmop.site/release/keenetic/opkg.sh" | sh; then
        echo -e "\n\033[1;31m❌ Не удалось выполнить скрипт установки!\033[0m"
        exit 1
      fi
      
      # 4. Устанавливаем пакет
      echo -e "\033[1;33m→ Установка neofit package...\033[0m"
      if ! opkg install neofit 2>&1 | sed 's/^/⟫ /'; then
        echo -e "\n\033[1;31m❌ Не удалось установить neofit package!\033[0m"
        exit 1
      fi
      
      # 5. Проверяем установку
      if ! is_installed "neofit"; then
        echo -e "\n\033[1;31m❌ Установка завершена, но пакет не установлен!\033[0m"
        exit 1
      fi
      
      # 6. Проверяем запуск сервиса
      sleep 2
      if pidof neofit >/dev/null 2>&1; then
        echo -e "\n\033[1;32m✅ Установка завершена\033[0m"
        echo -e "\033[1;33m→ Доступ к панели  neofit: http://${ROUTER_IP}:92\033[0m"
      else
        echo -e "\n\033[1;33m⚠️  Установка завершена, но сервис не запущен.\033[0m"
        echo -e "\033[1;37m   Попробуйте запустить вручную: /opt/etc/init.d/S99neofit start\033[0m"
      fi
      ;;
      
    x-ui)
      if is_installed "3x-ui"; then
        echo -e "\n\033[1;33m⚠️  x-ui уже установлен!\033[0m"
        echo -e "\033[1;37m   Используйте команду 'banner' чтобы посмотреть статус сервиса.\033[0m"
        exit 0
      fi
      
      if ! confirm "Вы хотите установить x-ui?" "y"; then
        echo -e "\n\033[1;33m⚠️  Установка отменена!\033[0m"
        exit 0
      fi
      
      echo -e "\033[1;32m🚀 Установка x-ui...\033[0m"
      
      # 1. Обновляем список пакетов
      echo -e "\033[1;33m→ Обновление списка пакетов...\033[0m"
      if ! opkg update >/dev/null 2>&1; then
        echo -e "\n\033[1;31m❌ Не удалось обновить список пакетов!\033[0m"
        exit 1
      fi
      
      # 2. Устанавливаем curl при необходимости
      if ! command -v curl >/dev/null 2>&1; then
        echo -e "\033[1;33m→ Установка curl...\033[0m"
        if ! opkg install curl >/dev/null 2>&1; then
          echo -e "\n\033[1;31m❌ Не удалось установить curl!\033[0m"
          exit 1
        fi
      fi
      
      # 3. Запускаем установочный скрипт
      echo -e "\033[1;33m→ Запуск скрипта установки...\033[0m"
      if ! curl -Ls "https://ground-zerro.github.io/release/keenetic/install-feed.sh" | sh; then
        echo -e "\n\033[1;31m❌ Не удалось выполнить скрипт установки!\033[0m"
        exit 1
      fi
      
      # 4. Устанавливаем пакет
      echo -e "\033[1;33m→ Установка 3x-ui package...\033[0m"
      if ! opkg install 3x-ui 2>&1 | sed 's/^/⟫ /'; then
        echo -e "\n\033[1;31m❌ Не удалось установить 3x-ui package!\033[0m"
        exit 1
      fi
      
      # 5. Проверяем установку
      if ! is_installed "3x-ui"; then
        echo -e "\n\033[1;31m❌ Установка завершена, но пакет не установлен!\033[0m"
        exit 1
      fi
      
      # 6. Проверяем запуск сервиса
      sleep 2
      if pidof x-ui >/dev/null 2>&1; then
        echo -e "\n\033[1;32m✅ Установка завершена\033[0m"
        echo -e "\033[1;33m→ Доступ к панели x-ui: http://${ROUTER_IP}:2053\033[0m"
      else
        echo -e "\n\033[1;33m⚠️  Установка завершена, но сервис не запущен.\033[0m"
        echo -e "\033[1;37m   Попробуйте запустить вручную: /opt/etc/init.d/S99_3x-ui start\033[0m"
      fi
      ;;
      
    hrneo)
      if is_installed "hrneo"; then
        echo -e "\n\033[1;33m⚠️  hrneo уже установлен!\033[0m"
        echo -e "\033[1;37m   Используйте команду 'banner' чтобы посмотреть статус сервиса.\033[0m"
        exit 0
      fi
      
      if ! confirm "Вы хотите установить hrneo?" "y"; then
        echo -e "\n\033[1;33m⚠️  Установка отменена!\033[0m"
        exit 0
      fi
      
      echo -e "\033[1;32m🚀 Установка hrneo...\033[0m"
      
      # 1. Обновляем список пакетов
      echo -e "\033[1;33m→ Обновление списка пакетов...\033[0m"
      if ! opkg update >/dev/null 2>&1; then
        echo -e "\n\033[1;31m❌ Не удалось обновить список пакетов!\033[0m"
        exit 1
      fi
      
      # 2. Устанавливаем curl при необходимости
      if ! command -v curl >/dev/null 2>&1; then
        echo -e "\033[1;33m→ Установка curl...\033[0m"
        if ! opkg install curl >/dev/null 2>&1; then
          echo -e "\n\033[1;31m❌ Не удалось установить curl!\033[0m"
          exit 1
        fi
      fi
      
      # 3. Запускаем установочный скрипт
      echo -e "\033[1;33m→ Запуск скрипта установки...\033[0m"
      if ! curl -Ls "https://ground-zerro.github.io/release/keenetic/install-neo.sh" | sh; then
        echo -e "\n\033[1;31m❌ Не удалось выполнить скрипт установки!\033[0m"
        exit 1
      fi
      
      # 4. Устанавливаем пакет
      echo -e "\033[1;33m→ Установка hrneo package...\033[0m"
      if ! opkg install hrneo 2>&1 | sed 's/^/⟫ /'; then
        echo -e "\n\033[1;31m❌ Не удалось установить hrneo package!\033[0m"
        exit 1
      fi
      
      # 5. Проверяем установку
      if ! is_installed "hrneo"; then
        echo -e "\n\033[1;31m❌ Установка завершена, но пакет не установлен!\033[0m"
        exit 1
      fi
      
      # 6. Проверяем запуск сервиса
      sleep 2
      if pidof hrneo >/dev/null 2>&1; then
        echo -e "\n\033[1;32m✅ Установка завершена\033[0m"
        echo -e "\033[1;33m→ Доступ к панели hrweb: http://${ROUTER_IP}:2000\033[0m"
      else
        echo -e "\n\033[1;33m⚠️  Установка завершена, но сервис не запущен.\033[0m"
        echo -e "\033[1;37m   Попробуйте запустить вручную: /opt/etc/init.d/S99hrneo start\033[0m"
      fi
      ;;
      
         
    magitrickle)
      if is_installed "magitrickle"; then
        echo -e "\n\033[1;33m⚠️  magitrickle уже установлен!\033[0m"
        echo -e "\033[1;37m   Используйте команду 'banner' чтобы посмотреть статус сервиса\033[0m"
        exit 0
      fi
      
      if ! confirm "Вы хотите установить magitrickle?" "y"; then
        echo -e "\n\033[1;33m⚠️  Установка отменена!\033[0m"
        exit 0
      fi
      
      echo -e "\033[1;32m🚀 Установка magitrickle...\033[0m"
      
      # 1. Добавляем репозиторий
      echo -e "\033[1;33m→ Добавление репозитория...\033[0m"
      if ! wget -qO- http://bin.magitrickle.dev/packages/add_repo.sh | sh; then
        echo -e "\n\033[1;31m❌ Не удалось добавить репозиторий!\033[0m"
        exit 1
      fi
      
      # 2. Обновляем список пакетов
      echo -e "\033[1;33m→ Обновление списка пакетов...\033[0m"
      if ! opkg update >/dev/null 2>&1; then
        echo -e "\n\033[1;31m❌ Не удалось обновить список пакетов!\033[0m"
        exit 1
      fi
      
      # 3. Проверяем наличие пакета
      if ! opkg list | grep -q "magitrickle"; then
        echo -e "\n\033[1;31m❌ Пакет 'magitrickle' не найден в репозиториях!\033[0m"
        echo -e "\033[1;37m   Возможные причины::\033[0m"
        echo -e "\033[1;37m   - Репозиторий не был добавлен корректно.\033[0m"
        echo -e "\033[1;37m   - Название пакета может быть другим (попробуйте 'magitrickled').\033[0m"
        echo -e "\033[1;37m   - Сервер репозитория может быть недоступен.\033[0m"
        exit 1
      fi
      
      # 4. Устанавливаем пакет
      echo -e "\033[1;33m→ Установка magitrickle package...\033[0m"
      if ! opkg install magitrickle 2>&1 | sed 's/^/⟫ /'; then
        echo -e "\n\033[1;31m❌ Не удалось установить magitrickle package!\033[0m"
        exit 1
      fi
      
      # 5. Проверяем установку
      if ! is_installed "magitrickle"; then
        echo -e "\n\033[1;31m❌ Установка завершена, но пакет не установлен!\033[0m"
        exit 1
      fi
      
      # 6. Запускаем сервис
      echo -e "\033[1;33m→ Запуск сервиса magitrickle....\033[0m"
      if [ -f "/opt/etc/init.d/S99magitrickle" ]; then
        if ! /opt/etc/init.d/S99magitrickle start 2>&1 | sed 's/^/⟫ /'; then
          echo -e "\n\033[1;33m⚠️  Сервис запущен, но с предупреждениями.\033[0m"
        fi
      else
        echo -e "\n\033[1;33m⚠️  Скрипт инициализации не найден, сервис может не запускаться автоматически.\033[0m"
      fi
      
      # 7. Проверяем запуск сервиса
      sleep 1
      if pidof magitrickled >/dev/null 2>&1; then
        echo -e "\n\033[1;32m✅ Установка завершена\033[0m"
        echo -e "\033[1;33m→ Доступ к панели magitrickle: http://${ROUTER_IP}:8080\033[0m"
      else
        echo -e "\n\033[1;33m⚠️  Установка завершена, но сервис не запущен.\033[0m"
        echo -e "\033[1;37m   Попробуйте запустить вручную: cat /opt/var/log/magitrickle.log\033[0m"
      fi
      ;;

	awg-manager)
	  if is_installed "awg-manager"; then
	    echo -e "\n\033[1;33m⚠️  awg-manager уже установлен!\033[0m"
	    exit 0
	  fi
	
	  if ! confirm "Вы хотите установить awg-manager?" "y"; then
	    echo -e "\n\033[1;33m⚠️  Установка отменена!\033[0m"
	    exit 0
	  fi
	
	  echo -e "\033[1;32m🚀 Установка awg-manager...\033[0m"
	
	  opkg update
	  opkg install curl
	
	  if ! curl -sL https://raw.githubusercontent.com/hoaxisr/awg-manager/main/scripts/install.sh | sh; then
	    echo -e "\n\033[1;31m❌ Ошибка установки awg-manager!\033[0m"
	    exit 1
	  fi
	
	  echo -e "\n\033[1;32m✅ awg-manager установлен!\033[0m"
	  ;;

	nfqws2)
	  if is_installed "nfqws2-keenetic"; then
	    echo -e "\n\033[1;33m⚠️  nfqws2 уже установлен!\033[0m"
	    exit 0
	  fi
	
	  if ! confirm "Вы хотите установить nfqws2 (с web интерфейсом)?" "y"; then
	    echo -e "\n\033[1;33m⚠️  Установка отменена!\033[0m"
	    exit 0
	  fi
	
	  echo -e "\033[1;32m🚀 Установка nfqws2...\033[0m"
	
	  # 🔴 Удаляем старую версию если есть
	  if is_installed "nfqws-keenetic" || is_installed "nfqws-keenetic-web"; then
	    echo -e "\033[1;33m→ Найдена старая версия nfqws, удаляем...\033[0m"
	    opkg remove nfqws-keenetic-web nfqws-keenetic >/dev/null 2>&1
	  fi
	
	  # зависимости
	  echo -e "\033[1;33m→ Установка зависимостей...\033[0m"
	  opkg update
	  opkg install ca-certificates wget-ssl
	  opkg remove wget-nossl >/dev/null 2>&1
	
	  # репозиторий nfqws2
	  echo -e "\033[1;33m→ Добавление репозитория nfqws2...\033[0m"
	  mkdir -p /opt/etc/opkg
	  echo "src/gz nfqws2-keenetic https://nfqws.github.io/nfqws2-keenetic/all" > /opt/etc/opkg/nfqws2-keenetic.conf
	
	  # репозиторий web
	  echo -e "\033[1;33m→ Добавление репозитория web...\033[0m"
	  echo "src/gz nfqws-keenetic-web https://nfqws.github.io/nfqws-keenetic-web/all" > /opt/etc/opkg/nfqws-keenetic-web.conf
	
	  # установка
	  echo -e "\033[1;33m→ Установка nfqws2...\033[0m"
	  opkg update
	  if ! opkg install nfqws2-keenetic 2>&1 | sed 's/^/⟫ /'; then
	    echo -e "\n\033[1;31m❌ Ошибка установки nfqws2!\033[0m"
	    exit 1
	  fi
	
	  echo -e "\033[1;33m→ Установка web интерфейса...\033[0m"
	  if ! opkg install nfqws-keenetic-web 2>&1 | sed 's/^/⟫ /'; then
	    echo -e "\n\033[1;31m❌ Ошибка установки web интерфейса!\033[0m"
	    exit 1
	  fi
	
	  echo -e "\n\033[1;32m✅ nfqws2 + web установлен!\033[0m"
	  ;;

	b4)
	  if is_installed "b4"; then
	    echo -e "\n\033[1;33m⚠️  b4 уже установлен!\033[0m"
	    exit 0
	  fi
	
	  if ! confirm "Вы хотите установить b4?" "y"; then
	    echo -e "\n\033[1;33m⚠️  Установка отменена!\033[0m"
	    exit 0
	  fi
	
	  echo -e "\033[1;32m🚀 Установка b4...\033[0m"
	
	  if ! wget -qO- https://raw.githubusercontent.com/DanielLavrushin/b4/main/install.sh | sh; then
	    echo -e "\n\033[1;31m❌ Ошибка установки b4!\033[0m"
	    exit 1
	  fi
	
	  echo -e "\n\033[1;32m✅ b4 установлен!\033[0m"
	  ;;
	  
    *)
      echo "Error: Unknown service '$1'"
      echo "Usage: install [neofit|x-ui|hrneo|hrweb|magitrickle]"
      exit 1
      ;;
  esac
}
    
    install_service "$SERVICE"
    exit 0
    ;;
    		
"update"|"custom-update")
    # Обработка обновления пакетов
    echo -e "\033[1;33m🔄 Проверка обновлений пакетов Entware...\033[0m"
    opkg update >/dev/null 2>&1
    UPGRADEABLE=$(opkg list-upgradable 2>/dev/null | wc -l)
    if [ "$UPGRADEABLE" -eq 0 ]; then
        echo -e "\n\033[1;32m✅ Все пакеты Entware обновлены до последней версии!\033[0m"
    else
        echo -e "\n\033[1;33m📦 Найдено $UPGRADEABLE пакет(ов), доступных для обновления\033[0m"
        echo -e "\033[1;32m🚀 Запуск обновления пакетов Entware...\033[0m"
        opkg upgrade 2>&1 | sed 's/^/⟫ /'
        echo -e "\n\033[1;32m✅ Обновление пакетов Entware завершено!\033[0m"
    fi

    # Обновление дашборда (ТИХО, кроме начального и конечного сообщений)
    echo -e "\n\033[1;33m🔄 Обновление Dashboard Script через установщик...\033[0m"
    curl -L -s "https://raw.githubusercontent.com/LostGit77/ENTWARE-Dashboard/refs/heads/dev/install_dashboard.sh" > /tmp/banner.sh
    if [ ! -s /tmp/banner.sh ]; then
      echo -e "\n\033[1;31m❌ Не удалось загрузить установочный скрипт!\033[0m"
      rm -f /tmp/banner.sh
      exit 1
    fi
    { printf "3\n0\n" | sh /tmp/banner.sh >/dev/null 2>&1; } 2>/dev/null
    rm -f /tmp/banner.sh
    echo -e "\n\033[1;32m✅ Процесс обновления Dashboard завершён!\033[0m"
    export TERM=xterm
    exec "$SCRIPT_PATH"
    # exit 0 
;;
	
"manager"|"custom-manager")
    echo -e "\033[1;32m🚀 Загрузка и запуск Entware Manager...\033[0m"
    echo -e "\033[1;33m→ Обновление списка пакетов...\033[0m"
    opkg update >/dev/null 2>&1
    
    echo -e "\033[1;33m→ Установка required packages...\033[0m"
    opkg install curl bash >/dev/null 2>&1
    
    echo -e "\033[1;33m→ Загрузка manager script...\033[0m"
    curl -O https://raw.githubusercontent.com/LostGit77/Entware-Disk-Manager/refs/heads/main/entware_disk_manager.sh 2>/dev/null
    
    if [ ! -f "entware_disk_manager.sh" ]; then
      echo -e "\n\033[1;31m❌ Не удалось загрузить скрипт менеджера!\033[0m"
      exit 1
    fi
    
    echo -e "\033[1;33m→ Запуск скрипта менеджера...\033[0m"
    bash entware_disk_manager.sh
    
	# Удаляем временный скрипт после выполнения
	rm -f entware_disk_manager.sh
	  
	echo -e "\n\033[1;32m✅ Сессия менеджера завершена!\033[0m"
	  
	# Добавляем паузу и возврат к баннеру
	echo -e "\033[1;37m\n Возврат к баннеру через 1 секунду...\033[0m"
	sleep 1
    export TERM=xterm
    exec "$SCRIPT_PATH" 
	;;
	
"link"|"custom-link")
    echo ""
    echo -e "${CLR_BLUE}🔗 ОФИЦИАЛЬНЫЕ ИСТОЧНИКИ:${CLR_RESET}"
    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "  • neofit..........: https://github.com/pegakmop/neofit"
    echo -e "  • hrneo/hrweb.....: https://github.com/Ground-Zerro/HydraRoute/tree/main/Neo"
    echo -e "  • magitrickle.....: https://gitlab.com/magitrickle/magitrickle${CLR_RESET}"
	echo -e "                      https://magitrickle.dev/docs/getting-started/entware/"
    echo -e "  • Полезные скрипты: https://www.pegakmop.site"
	echo -e "  • AWG Manager.....: https://github.com/hoaxisr/awg-manager"
	echo -e "  • NFQWS2..........: https://github.com/nfqws/nfqws2-keenetic"
	echo -e "  • NFQWS-WEB.......: https://github.com/nfqws/nfqws-keenetic-web"
	echo -e "  • B4..............: https://github.com/DanielLavrushin/b4"
    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 0
    ;;
	
"help"|"custom-help")
    echo ""
    echo -e "📚 СПРАВОЧНАЯ ИНФОРМАЦИЯ:"
    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "  • install [сервис]  - Установка сервиса: neofit, x-ui, hrneo, magitrickle"
	echo -e "                        awg-manager, nfqws2, b4"
    echo -e "                        Пример: install neofit"
    echo -e ""
    echo -e "  • remove [сервис]   - Удаление сервиса: neofit, x-ui, hrneo, magitrickle"
	echo -e "                        awg-manager, nfqws2, b4"
    echo -e "                        Пример: remove x-ui"
    echo -e ""
    echo -e "  • update            - Обновление всех пакетов Entware (opkg update, opkg upgrade)"
    echo -e "                      - Плюс обновление и перезапуск Dashboarda"
    echo -e "                        Команда: update"
    echo -e ""
    echo -e "  • banner            - Повторный вывод главного баннера"
    echo -e "                        Команда: banner"
    echo -e ""
    echo -e "  • link              - Просмотр официальных источников"
    echo -e "                        Команда: link"
    echo -e ""
    echo -e "  • manager           - Запуск менеджера дисков и бекапов Entware"
    echo -e "                        Команда: manager"
    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 0
    ;;
	
"remove"|"custom-remove")
    # Обработка удаления сервисов
    if [ -z "$1" ]; then
	  echo "❗ Укажите сервис для удаления"
	  echo "👉 Использование: remove <сервис>"
	  echo "📦 Доступные сервисы: neofit, x-ui, hrneo, magitrickle, awg-manager, nfqws2, b4"
	  echo "💡 Пример: remove hrneo"
      exit 1
    fi
    
    SERVICE="$1"
    
	remove_service() {
	  case "$1" in
		neofit)
		  if ! is_installed "neofit"; then
			echo -e "\n\033[1;33m⚠️  Neofit не установлен!\033[0m"
			exit 0
		  fi
		  
		  if ! confirm "Вы хотите удалить Neofit и все зависимости?" "n"; then
			echo -e "\n\033[1;33m⚠️  Удаление отменено!\033[0m"e
			exit 0
		  fi
		  
		  echo -e "\033[1;31m🗑️  Удаление neofit...\033[0m"
		  echo -e "\033[1;33m→ Удаление neofit package...\033[0m"
		  opkg remove neofit 2>&1 | sed 's/^/⟫ /'
		  
		  # Удаляем все зависимости
		  for pkg in xray xray-core sing-box-go; do
			if is_installed "$pkg"; then
			  echo -e "\033[1;33m→ Удаление $pkg...\033[0m"
			  opkg remove "$pkg" 2>&1 | sed 's/^/⟫ /'
			fi
		  done
		  
		  echo -e "\n\033[1;32m✅ Neofit и все зависимости полностью удалёны!\033[0m"
		  ;;
		  
		x-ui)
		  if ! is_installed "3x-ui"; then
			echo -e "\n\033[1;33m⚠️  x-ui не установлен!\033[0m"
			exit 0
		  fi
		  
		  if ! confirm "Вы хотите удалить x-ui и все конфигурационные файлы?" "n"; then
			echo -e "\n\033[1;33m⚠️  Удаление отменено!\033[0m"
			exit 0
		  fi
		  
		  echo -e "\033[1;31m🗑️  Удаление x-ui...\033[0m"
		  echo -e "\033[1;33m→ Удаление 3x-ui package...\033[0m"
		  opkg remove 3x-ui 2>&1 | sed 's/^/⟫ /'
		  
		  # Полное удаление конфигов
		  echo -e "\033[1;33m→ Удаление конфигурационных файлов...\033[0m"
		  rm -rf /opt/etc/x-ui/ 2>&1 | sed 's/^/⟫ /'
		  rm -rf /opt/var/log/x-ui/ 2>&1 | sed 's/^/⟫ /'
		  
		  echo -e "\n\033[1;32m✅ x-ui и все конфигурационные файлы полностью удалёны!\033[0m"
		  ;;
		  
		hrneo)
		  if ! is_installed "hrneo"; then
			echo -e "\n\033[1;33m⚠️  hrneo не установлен!\033[0m"
			exit 0
		  fi
		  
		  if ! confirm "Вы хотите удалить hrneo and hrweb completely?" "n"; then
			echo -e "\n\033[1;33m⚠️  Удаление отменено!\033[0m"
			exit 0
		  fi
		  
		  echo -e "\033[1;31m🗑️  Удаление hrneo и hrweb...\033[0m"
		  echo -e "\033[1;33m→ Запуск скрипта полного удаления...\033[0m"
		  curl -Ls "https://ground-zerro.github.io/release/keenetic/hr-uninstall.sh" | sh 2>&1 | sed 's/^/⟫ /'
		  
		  echo -e "\n\033[1;32m✅ hrneo и hrweb полностью удалён!\033[0m"
		  ;;
		  
		hrweb)
		  if ! is_installed "hrweb"; then
			echo -e "\n\033[1;33m⚠️  hrweb не установлен!\033[0m"
			exit 0
		  fi
		  
		  # hrweb полностью входит в состав hrneo
		  echo -e "\n\033[1;33m⚠️  hrweb является частью установки hrneo.\033[0m"
		  echo -e "\033[1;33m   Чтобы удалить hrweb, необходимо удалить hrneo.:\033[0m"
		  echo -e "\033[1;33m   Удаление hrneo\033[0m"
		  exit 0
		  ;;
		  
		magitrickle)
		  if ! is_installed "magitrickle"; then
			echo -e "\n\033[1;33m⚠️  magitrickle не установлен!\033[0m"
			exit 0
		  fi
		  
		  if ! confirm "Вы хотите удалить magitrickle?" "n"; then
			echo -e "\n\033[1;33m⚠️  Удаление отменено!\033[0m"
			exit 0
		  fi
		  
		  echo -e "\033[1;31m🗑️  Удаление magitrickle...\033[0m"
		  
		  # Останавливаем сервис
		  echo -e "\033[1;33m→ Остановка службы magitrickle...\033[0m"
		  if [ -f "/opt/etc/init.d/S99magitrickle" ]; then
			/opt/etc/init.d/S99magitrickle stop 2>&1 | sed 's/^/⟫ /'
		  fi
		  
		  # Удаляем пакет
		  echo -e "\033[1;33m→ Удаление magitrickle package...\033[0m"
		  opkg remove magitrickle 2>&1 | sed 's/^/⟫ /'
		  
		  # Удаляем конфигурацию
		  echo -e "\033[1;33m→ Удаление конфигурационных файлов...\033[0m"
		  rm -rf /opt/var/lib/magitrickle 2>&1 | sed 's/^/⟫ /'
		  rm -f /opt/etc/opkg/magitrickle.conf 2>&1 | sed 's/^/⟫ /'
		  
		  echo -e "\n\033[1;32m✅ magitrickle полностью удалён!\033[0m"
		  ;;

		awg-manager)
		  opkg remove awg-manager
		  rm -rf /opt/etc/awg-manager
		  echo "Удалён awg-manager"
		  ;;
		
		nfqws2)
		  if ! is_installed "nfqws2-keenetic" && ! is_installed "nfqws-keenetic-web"; then
			echo -e "\n\033[1;33m⚠️  nfqws2 не установлен!\033[0m"
			exit 0
		  fi
		
		  if ! confirm "Вы хотите удалить nfqws2 и web интерфейс?" "n"; then
			echo -e "\n\033[1;33m⚠️  Удаление отменено!\033[0m"
			exit 0
		  fi
		
		  echo -e "\033[1;31m🗑️  Удаление nfqws2...\033[0m"
		
		  opkg remove --autoremove nfqws2-keenetic 2>&1 | sed 's/^/⟫ /'
		  opkg remove --autoremove nfqws-keenetic-web 2>&1 | sed 's/^/⟫ /'

		  echo -e "\033[1;33m→ Удаление конфигурационных файлов...\033[0m"
		  rm -rf /opt/etc/nfqws2
		
		  echo -e "\n\033[1;32m✅ nfqws2 полностью удалён!\033[0m"
		  ;;
		
		b4)
		  curl -fsSL https://raw.githubusercontent.com/DanielLavrushin/b4/main/install.sh | sh -s -- --remove
		  echo "Удалён b4"
		  ;;
		  
		*)
		  echo "Ошибка: Неизвестная служба '$1'"
		  echo "Использование: remove [neofit|x-ui|hrneo|hrweb|magitrickle]"
		  exit 1
		  ;;
	  esac
	}
    
    remove_service "$SERVICE"
    exit 0
    ;;
esac

# ===== Если запущен как баннер (без специальных аргументов) =====

# Загрузка профиля
. /opt/etc/profile

# ===== ANSI Цвета =====
CLR_BLACK="\033[1;30m"
CLR_DIM_BLACK="\033[0;30m"
CLR_RED="\033[0;31m"
CLR_GREEN="\033[0;32m"
CLR_YELLOW="\033[0;33m"
CLR_BLUE="\033[0;34m"
CLR_MAGENTA="\033[0;35m"
CLR_CYAN="\033[0;36m"
CLR_WHITE="\033[0;37m"
CLR_DIM_BLUE="\033[1;36m"
CLR_RESET="\033[0m"

# ===== Очистка экрана =====
printf "\033c"
printf "${CLR_BLACK}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CLR_RESET}\n"
printf "                     ${CLR_DIM_BLUE}🌐 ENTWARE Router Management 🛠️${CLR_RESET}\n"
printf "  ${CLR_BLACK}Информация о системе • Установка сервисов • Бэкап • Управление дисками${CLR_RESET}\n"
printf "${CLR_BLACK}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CLR_RESET}\n"

# ===== Обновление =====
opkg update >/dev/null 2>&1

# ===== Модель роутера =====
MODEL="$(
  ndmc -c "show version" 2>/dev/null \
  | awk -F'[":]' '/[Mm]odel/ {gsub(/[ \t]+/, "", $2); print $2; exit}'
)"

# ===== Публичный IP =====
IP_ADDRESS="$(wget -qO- https://api.ipify.org   2>/dev/null || echo 'Не определено')"

# ===== Сетевой интерфейс =====
NETWORK_INTERFACE="$(
  ip -o -4 addr show 2>/dev/null \
  | awk '!/ lo / {print $2; exit}'
)"

# ===== Локальный IP =====
IP_ADDRESS_LOCAL="$(get_router_ip)"

# ===== Информация о процессоре =====
CPU_MODEL="$(
  awk '
    BEGIN { FS = ":"; found = 0 }
    !found && /model name|system type|Processor/ {
      gsub(/^[ \t]+|[ \t]+$/, "", $2) 
      if ($2 != "") {
        print $2
        found = 1
      }
    }
    END { if (!found) print "Не определено" }
  ' /proc/cpuinfo
)"

# ===== Нагрузка на систему =====
SYSTEM_LOAD="$(
  awk '
    {
      load_1min = $1
      load_5min = $2
      load_15min = $3
      print load_1min "/" load_5min "/" load_15min
      exit
    }
  ' /proc/loadavg
)"

# ===== Температура процессора =====
if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
  CPU_TEMPERATURE=$(awk '{printf "%.0f°C\n", $1/1000}' /sys/class/thermal/thermal_zone0/temp)
else
  CPU_TEMPERATURE="Не определено"
fi

# ===== Колличество ядер =====
CPU_CORES_COUNT="$(
  awk '/^processor/ { count++ } END { print (count+0) }' /proc/cpuinfo 2>/dev/null
)"
if [ $? -ne 0 ] || [ -z "$CPU_CORES_COUNT" ] || [ "$CPU_CORES_COUNT" = "0" ]; then
  CPU_CORES_COUNT="?"
fi

# ===== Температура Wi-Fi =====
if ndmc -c "show interface WifiMaster0" 2>/dev/null | grep -q "temperature"; then
    WIFI_24G_TEMP=$(ndmc -c "show interface WifiMaster0" 2>/dev/null | awk -F": " '/temperature/ {print $2}')
    if [ -n "$WIFI_24G_TEMP" ]; then
        WIFI_TEMPERATURE_24G="${WIFI_24G_TEMP}°C"
    else
        WIFI_TEMPERATURE_24G="Не определено"
    fi
else
    WIFI_TEMPERATURE_24G="Не определено"
fi

if ndmc -c "show interface WifiMaster1" 2>/dev/null | grep -q "temperature"; then
    WIFI_5G_TEMP=$(ndmc -c "show interface WifiMaster1" 2>/dev/null | awk -F": " '/temperature/ {print $2}')
    if [ -n "$WIFI_5G_TEMP" ]; then
        WIFI_TEMPERATURE_5G="${WIFI_5G_TEMP}°C"
    else
        WIFI_TEMPERATURE_5G="Не определено"
    fi
else
    WIFI_TEMPERATURE_5G="Не определено"
fi

# Объединяем значения в одну переменную (если нужно общее значение)
if [ "$WIFI_TEMPERATURE_24G" != "Не определено" ] && [ "$WIFI_TEMPERATURE_5G" != "Не определено" ]; then
    WIFI_TEMPERATURE="2.4G: ${WIFI_TEMPERATURE_24G}, 5G: ${WIFI_TEMPERATURE_5G}"
elif [ "$WIFI_TEMPERATURE_24G" != "Не определено" ]; then
    WIFI_TEMPERATURE="$WIFI_TEMPERATURE_24G"
elif [ "$WIFI_TEMPERATURE_5G" != "Не определено" ]; then
    WIFI_TEMPERATURE="$WIFI_TEMPERATURE_5G"
else
    WIFI_TEMPERATURE="Не определено"
fi

# ===== Оперативная память =====
RAM="$(
  free -m 2>/dev/null | awk '/Mem:/ { p = ($2 > 0 ? int(($3*100)/$2 + 0.5) : 0); printf "%d%% из (%sM)", p, $2; exit }'
)"


# ===== Диск /opt =====
DISK_INFO="$(
  df -h 2>/dev/null | awk '$6=="/opt" { gsub(/%/, "", $5); size=$2; usage=$5; print usage"% из ("size")"; exit }'
)"

# ===== Проверка на обновления пакетов =====
UPGRADABLE_LIST="$(opkg list-upgradable 2>/dev/null)"
UPGRADEABLE_COUNT=0
if [ -n "$UPGRADABLE_LIST" ]; then
	UPGRADEABLE_COUNT=$(echo "$UPGRADABLE_LIST" | grep -c .)
	if [ "$UPGRADEABLE_COUNT" -lt 0 ] || [ -z "$UPGRADEABLE_COUNT" ]; then
		UPGRADEABLE_COUNT=0
	fi
fi

# ===== Функция для получения имени пакета =====
get_package() {
  case "$1" in
    "x-ui") echo "3x-ui" ;;
	"nfqws2") echo "nfqws2-keenetic" ;;
    *) echo "$1" ;;
  esac
}

# ===== Узнать, на каком диске и с какой меткой находится Entware =====
ENTWARE_DEVICE=$(mount | awk '$3=="/opt" {print $1}')
ENTWARE_LABEL="N/A"
if [ -n "$ENTWARE_DEVICE" ]; then
  ENTWARE_LABEL=$(blkid "$ENTWARE_DEVICE" | sed -n 's/.*LABEL="\([^"]*\)".*/\1/p')
  if [ -z "$ENTWARE_LABEL" ]; then
    ENTWARE_LABEL="(no label)"
  fi
fi

# ===== Вывод информации с проверкой сервисов =====
printf "\n${CLR_WHITE}\e[1m💻 Статус роутера:\e[0m${CLR_RESET}\n"
printf "${CLR_YELLOW}   ➤  Модель роутера.............:${CLR_RESET} %s\n" "$MODEL"
printf "${CLR_YELLOW}   ➤  Время работы...............:${CLR_RESET} %s\n" "$(uptime -p)"
printf "${CLR_CYAN}   ➤  Внешний IP.................:${CLR_RESET} %s\n" "$IP_ADDRESS"
printf "${CLR_CYAN}   ➤  Локальный IP...............:${CLR_RESET} %s\n" "$IP_ADDRESS_LOCAL"
printf "${CLR_GREEN}   ➤  CPU........................:${CLR_RESET} %s\n" "$CPU_MODEL"
printf "${CLR_GREEN}   ➤  Нагрузка на CPU............:${CLR_RESET} %s\n" "$SYSTEM_LOAD"
printf "${CLR_GREEN}   ➤  Колличество ядер...........:${CLR_RESET} %s\n" "$CPU_CORES_COUNT"
printf "${CLR_GREEN}   ➤  Температура CPU............:${CLR_RESET} %s\n" "$CPU_TEMPERATURE"
printf "${CLR_BLUE}   ➤  Температура WiFi 2.4G......:${CLR_RESET} %s\n" "$WIFI_TEMPERATURE_24G"
printf "${CLR_BLUE}   ➤  Температура WiFi 5G........:${CLR_RESET} %s\n" "$WIFI_TEMPERATURE_5G"
printf "${CLR_MAGENTA}   ➤  Диск (/opt)................:${CLR_RESET} %s\n" "$DISK_INFO"
printf "${CLR_MAGENTA}   ➤  Оперативная память.........:${CLR_RESET} %s\n" "$RAM"
printf "${CLR_MAGENTA}   ➤  Entware Диск...............:${CLR_RESET} %s (Label: %s)\n" "$ENTWARE_DEVICE" "$ENTWARE_LABEL"

printf "\n${CLR_BLACK}Основано на идее и некоторых элементах скрипта custom-banner от @pegakmop${CLR_RESET}\n"
printf "${CLR_BLACK}Полезные скрипты: https://www.pegakmop.site${CLR_RESET}\n"

# ===== Проверка основных сервисов =====
SERVICES_MAIN="neofit x-ui hrneo hrweb magitrickle awg-manager nfqws2 b4"
ROUTER_IP="$(get_router_ip)"
RUNNING_SERVICES=""
OTHER_SERVICES=""

printf "\n${CLR_WHITE}\e[1m✅ Запущенные сервисы:\e[0m${CLR_RESET}\n"
for SVC in $SERVICES_MAIN; do
  PKG=$(get_package "$SVC")
  
  # Проверяем установлен ли пакет
  if opkg list-installed | grep -q "^${PKG} "; then
    # Проверяем запущен ли процесс
    case "$SVC" in
	"neofit")
	  if pidof neofit >/dev/null 2>&1; then
		RUNNING_SERVICES="$RUNNING_SERVICES$(printf "   🟩 %-12s ${CLR_GREEN}запущен${CLR_RESET} → http://%s:92\n" "$SVC" "$ROUTER_IP")"
	  else
		OTHER_SERVICES="$OTHER_SERVICES$(printf "   🟨 %-12s ${CLR_YELLOW}установлен, но остановлен${CLR_RESET}\n" "$SVC")"
	  fi
	  ;;
	"x-ui")
	  if pidof x-ui >/dev/null 2>&1; then
	    RUNNING_SERVICES="$RUNNING_SERVICES$(printf "   🟩 %-12s ${CLR_GREEN}запущен${CLR_RESET} → http://%s:2053\n" "$SVC" "$ROUTER_IP")"
	  else
	    OTHER_SERVICES="$OTHER_SERVICES$(printf "   🟨 %-12s ${CLR_YELLOW}установлен, но остановлен${CLR_RESET}\n" "$SVC")"
	  fi
	  ;;
	 "hrweb")
		if pidof hrneo >/dev/null 2>&1 && pidof hrweb >/dev/null 2>&1; then
		  RUNNING_SERVICES="$RUNNING_SERVICES$(printf "   🟩 %-12s ${CLR_GREEN}запущен${CLR_RESET} → http://%s:2000\n" "$SVC" "$ROUTER_IP")"
		else
		  OTHER_SERVICES="$OTHER_SERVICES$(printf "   🟨 %-12s ${CLR_YELLOW}установлен, но остановлен${CLR_RESET}\n" "$SVC")"
		fi
		;;
     "magitrickle")
        if pidof magitrickled >/dev/null 2>&1; then
          RUNNING_SERVICES="$RUNNING_SERVICES$(printf "   🟩 %-12s ${CLR_GREEN}запущен${CLR_RESET} → http://%s:8080\n" "$SVC" "$ROUTER_IP")"
        else
          OTHER_SERVICES="$OTHER_SERVICES$(printf "   🟨 %-12s ${CLR_YELLOW}установлен, но остановлен${CLR_RESET}\n" "$SVC")"
        fi
        ;;
	"awg-manager")
	  if pidof awg-manager >/dev/null 2>&1; then
		RUNNING_SERVICES="$RUNNING_SERVICES$(printf "   🟩 %-12s ${CLR_GREEN}запущен${CLR_RESET} → http://%s:2222\n" "$SVC" "$ROUTER_IP")"
	  else
		OTHER_SERVICES="$OTHER_SERVICES$(printf "   🟨 %-12s ${CLR_YELLOW}установлен, но остановлен${CLR_RESET}\n" "$SVC")"
	  fi
	  ;;

	"nfqws2")
	  if pidof nfqws2 >/dev/null 2>&1; then
	    RUNNING_SERVICES="$RUNNING_SERVICES$(printf "   🟩 %-12s ${CLR_GREEN}запущен${CLR_RESET} → http://%s:90\n" "$SVC" "$ROUTER_IP")"
	  else
	    OTHER_SERVICES="$OTHER_SERVICES$(printf "   🟨 %-12s ${CLR_YELLOW}установлен, но остановлен${CLR_RESET}\n" "$SVC")"
	  fi
	  ;;
	"b4")
	  if pidof b4 >/dev/null 2>&1; then
	    RUNNING_SERVICES="$RUNNING_SERVICES$(printf "   🟩 %-12s ${CLR_GREEN}запущен${CLR_RESET} → http://%s:7000\n" "$SVC" "$ROUTER_IP")"
	  else
	    OTHER_SERVICES="$OTHER_SERVICES$(printf "   🟨 %-12s ${CLR_YELLOW}установлен, но остановлен${CLR_RESET}\n" "$SVC")"
	  fi
	  ;;
		
      *)
        if pidof "$SVC" >/dev/null 2>&1; then
          RUNNING_SERVICES="$RUNNING_SERVICES$(printf "   🟩 %-12s ${CLR_GREEN}запущен${CLR_RESET}\n" "$SVC")"
        else
          OTHER_SERVICES="$OTHER_SERVICES$(printf "   🟨 %-12s ${CLR_YELLOW}установлен, но остановлен${CLR_RESET}\n" "$SVC")"
        fi
        ;;
    esac
  else
    OTHER_SERVICES="$OTHER_SERVICES$(printf "   ⬜ %-12s ${CLR_YELLOW}не установлен${CLR_RESET}\n" "$SVC")"
  fi
done

echo -e "%s" "$RUNNING_SERVICES"
echo -e "%s" "$OTHER_SERVICES"

# ===== Проверка proxy-сервисов (xray/sing-box) =====
PROXY_RUNNING=""
PROXY_OTHER=""

printf "\n${CLR_WHITE}\e[1m✅ Прокси-сервисы:\e[0m${CLR_RESET}\n"
for SVC in xray sing-box mihomo; do
  if pidof "$SVC" >/dev/null 2>&1; then
    PROXY_RUNNING="$PROXY_RUNNING$(printf "   🟩 %-12s ${CLR_GREEN}запущен${CLR_RESET}\n" "$SVC")"
  else
    PROXY_OTHER="$PROXY_OTHER$(printf "   🟥 %-12s ${CLR_RED}остановлен${CLR_RESET}\n" "$SVC")"
  fi
done

echo -e "%s" "$PROXY_RUNNING"
echo -e "%s" "$PROXY_OTHER"

printf "\n${CLR_WHITE}\e[1m🔄 Доступно обновлений:\e[0m${CLR_RESET} %s\n" "$UPGRADEABLE_COUNT"


# ===== Вывод списка обновляемых пакетов (только если есть что выводить) =====
if [ "$UPGRADEABLE_COUNT" -gt 0 ]; then
    printf "   ${CLR_CYAN}%-15s${CLR_RESET}     ${CLR_RED}%-12s${CLR_RESET}   ${CLR_GREEN}%s${CLR_RESET}\n" "Имя пакета" "Текущая версия" "Новая версия"
	printf '%s\n' "$UPGRADABLE_LIST" | (
		while IFS= read -r line; do
			if [ -n "$line" ]; then
				pkg_name="$(printf '%s' "$line" | awk '{print $1}')"
				old_ver="$(printf '%s' "$line" | awk '{print $3}')"
				new_ver="$(printf '%s' "$line" | awk '{print $5}')"
				printf "   ${CLR_CYAN}➤  %-15s${CLR_RESET} ${CLR_RED}→ %-12s${CLR_RESET} → ${CLR_GREEN}%s${CLR_RESET}\n" "$pkg_name" "$old_ver" "$new_ver"
			fi
		done
	)
fi

# ===== ВАЖНЫЕ КОМАНДЫ (НАЖМИТЕ ENTER ДЛЯ ОБНОВЛЕНИЯ) =====
printf "\n${CLR_BLACK}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CLR_RESET}\n"
printf "                     ${CLR_BLACK}ПОЛЕЗНЫЕ КОМАНДЫ ДЛЯ УПРАВЛЕНИЯ${CLR_RESET}                         \n"
printf "${CLR_BLACK}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CLR_RESET}\n"
printf " ${CLR_CYAN}🛠️  Установка сервисов........:${CLR_RESET} ${CLR_WHITE}install${CLR_RESET}\n"
printf " ${CLR_YELLOW}🧹 Удаление сервисов.........:${CLR_RESET} ${CLR_WHITE}remove${CLR_RESET}\n"
printf " ${CLR_GREEN}🔄 Обновление пакетов........:${CLR_RESET} ${CLR_WHITE}update${CLR_RESET}\n"
printf " ${CLR_MAGENTA}💾 Менеджер дисков & backup..:${CLR_RESET} ${CLR_WHITE}manager${CLR_RESET}\n"
printf " ${CLR_BLUE}🏠 Вернуться к баннеру.......:${CLR_RESET} ${CLR_WHITE}banner${CLR_RESET}\n"
printf " ${CLR_MAGENTA}🔗 Источники и ссылки........:${CLR_RESET} ${CLR_WHITE}link${CLR_RESET}\n"
printf " ${CLR_GREEN}❓ Справочная информация.....:${CLR_RESET} ${CLR_WHITE}help${CLR_RESET}\n"
printf "${CLR_BLACK}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CLR_RESET}\n"
