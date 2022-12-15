#!/bin/bash
#Скрипт для отправки сообщений из журнала событий Битрикс24 на сервер syslog
#Syslog сообщение по RFC-5424
#Скрипт сделать исполняемым и добавить в crontab
LAST_ID=""
#Проверим, существует ли файл в котором записан ID последней обработанной записи
FILE=lastid
if [ -f "$FILE" ]; then
#Считываем ID последней обработанной записи в переменную
	LAST_ID=$(cat $FILE)
fi
#Проверяем является ли переменная строкой состоящей из цифр
if ! [[ "$LAST_ID" =~ ^[0-9]+$ ]]; then
#Если нет, считаем переменную невалидной и обнуляем
	LAST_ID=""
fi
#Проверяем, что последний обработанный ID меньше последнего в базе
#!!!ВНИМАНИЕ!!! В строке ниже bitrix0 заменить на актуального пользователя mysql
#Следующим параметром указать пароль в виде -p<пароль> БЕЗ ПРОБЕЛОВ
#sitemanager заменить актуальным названием БД
CURRENT_ID=($(mysql -u bitrix0 -p<password> -e 'USE sitemanager;SELECT ID FROM b_event_log ORDER BY ID DESC LIMIT 1;'))
if [[ $LAST_ID > ${CURRENT_ID[1]} ]]; then
#Если нет, считаем переменную невалидной и обнуляем
	LAST_ID=""
elif [[ $LAST_ID = ${CURRENT_ID[1]} ]]; then
#Если равны, значит новых сообщений нет, завершаем скрипт
	exit 0
fi
#Формируем sql-запрос
QUERY="SELECT
	b_event_log.ID, 
	b_event_log.TIMESTAMP_X,
	SEVERITY,
	AUDIT_TYPE_ID,
	MODULE_ID,
	ITEM_ID,
	REMOTE_ADDR,
	REQUEST_URI,
	CONCAT(b_user.NAME, ' ', b_user.LAST_NAME) AS USER_NAME,
	DESCRIPTION,
    USER_ID
FROM b_event_log 
LEFT JOIN b_user ON USER_ID = b_user.ID"
if [ "$LAST_ID" = "" ]; then
#Если последний обработанный ID по каким-то причинам невалиден, выбираем последние 10 записей
	QUERY=$QUERY" ORDER BY b_event_log.ID DESC LIMIT 10"
else
	QUERY=$QUERY" WHERE b_event_log.ID >"$LAST_ID
fi
#Выполняем sql-запрос
#!!!ВНИМАНИЕ!!! В строке ниже bitrix0 заменить на актуального пользователя mysql
#Следующим параметром указать пароль в виде -p<пароль> БЕЗ ПРОБЕЛОВ
#sitemanager заменить актуальным названием БД
QUERY_RESULT=$(mysql -u bitrix0 -p<password> -e "USE sitemanager;$QUERY;")
#Разбиваем полученный ответ в массив строк
IFS=$'\n';LINES_ARRAY=($QUERY_RESULT)
#Отрезаем у массива нулевой элемент - строка с заголовками столбцов
LINES_ARRAY=("${LINES_ARRAY[@]:1}")
#Обходим массив
for i in ${LINES_ARRAY[@]}
do
#Разбиваем строку в массив значений
    IFS=$'\t' read -ra PARAMETERS_ARRAY <<< "$i"
#Начинаем формирование сообщения
    MSG=RECORD_ID="${PARAMETERS_ARRAY[0]}"
#Сохраняем ID записи в переменную - нужно будет в конце скрипта сохранить ее в файл
	LAST_ID="${PARAMETERS_ARRAY[0]}"
#Продолжаем формирование сообщения
    MSG=$MSG" SEVERITY=${PARAMETERS_ARRAY[2]}"
    MSG=$MSG" MODULE_ID=${PARAMETERS_ARRAY[4]}"
#Если ITEM_ID равен ID пользователя, берем вместо ID имя-фамилию
    if [ "${PARAMETERS_ARRAY[5]}" = "${PARAMETERS_ARRAY[10]}" ]; then
        MSG=$MSG" ITEM_ID=${PARAMETERS_ARRAY[8]}"
    else
        MSG=$MSG" ITEM_ID=${PARAMETERS_ARRAY[5]}"
    fi
    MSG=$MSG" REMOTE_ADDR=${PARAMETERS_ARRAY[6]}"
    MSG=$MSG" REQUEST_URI=${PARAMETERS_ARRAY[7]}"
    MSG=$MSG" USER_NAME=${PARAMETERS_ARRAY[8]}"
    MSG=$MSG" DESCRIPTION=${PARAMETERS_ARRAY[9]}"
#Преобразуем дату в формат ISO-86001, как требуется по RFC-5424
    ISO_DATE=$(date -d "${PARAMETERS_ARRAY[1]}" -Iseconds)
#Добавляем символ кодировки UTF-8 перед текстовой частью, как требуется по RFC-5424
    MSG=$(echo -e "\uFEFF")$MSG
#Формируем итоговое сообщение
    RESULT_MES='<150>1 '$ISO_DATE' '$(hostname --fqdn)' bitrix - '${PARAMETERS_ARRAY[3]}' - '$MSG
#Отправляем итоговое сообщение на сервер syslog
#!!ВНИМАНИЕ!! В строке ниже после /dev/ заменить текст на соответствующий для настроек syslog сервера
#Формат <Протокол(tcp или udp)>/<ip-адрес syslog сервера>/<порт syslog сервера>
    echo $RESULT_MES > /dev/<tcp or udp>/<ip address>/<port>
#    echo $RESULT_MES
done
if ! [ "$LAST_ID" = ""  ];then
	echo $LAST_ID > $FILE
fi