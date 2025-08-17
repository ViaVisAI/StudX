# Решение: Визуальный шум в корне репозитория

## Проблема
Конфигурационные файлы (.eslintrc, .prettierrc, cspell.json и др.) создают визуальный шум в VS Code Explorer

## Решение
Скрыть файлы через `.vscode/settings.json` с помощью `files.exclude`

## Реализация
```json
"files.exclude": {
  ".editorconfig": true,
  ".eslintrc.json": true,
  ".prettierrc": true,
  ".prettierignore": true,
  "cspell.json": true,
  "jsconfig.json": true,
  ".nvmrc": true
}
```

## Результат
- Файлы остаются в корне и работают
- VS Code их не показывает в Explorer
- Доступны через поиск (Ctrl+P)
- Требуется перезапуск окна VS Code

## Важно
НЕ перемещать файлы в папки - сломает инструменты