# SmartPlanner

SmartPlanner — кроссплатформенное приложение для управления задачами,
отслеживания прогресса и чтения новостей. В репозитории находятся две
нативные реализации: iOS на Swift/UIKit и Android на Kotlin/Jetpack Compose.

## Возможности

- создание задач с описанием, приоритетом, флагом и дедлайном;
- фильтрация по сроку и сортировка по дате или приоритету;
- группировка ближайших задач по неделе и месяцу;
- отметка задач выполненными;
- удаление задач свайпом в iOS;
- дашборд со статистикой за неделю, месяц или всё время;
- календарь с активными, выполненными и просроченными задачами;
- просмотр задач за выбранный день;
- лента главных новостей The New York Times;
- фоновое обновление и локальное кеширование новостей и изображений;
- сохранение задач между запусками приложения.

## Платформы и технологии

| Платформа | Технологии | Минимальная версия |
|---|---|---|
| iOS | Swift 5, UIKit, Auto Layout, MVVM, URLSession, Codable | iOS 17.6 |
| Android | Kotlin, Jetpack Compose, Material 3, StateFlow, Coroutines | Android 7.0 (API 24) |

Обе версии используют нативный UI и разделение на доменный слой, слой данных
и представление. Сторонние зависимости iOS не требуются. Android использует
Gradle и Gson.

## Структура репозитория

```text
SmartPlanner/
├── Android/         # Android-приложение на Kotlin и Jetpack Compose
├── iOS/             # iOS-приложение на Swift и UIKit
└── docs/adr/        # архитектурные решения
```

### iOS

```text
iOS/
├── SmartPlanner.xcodeproj
├── SmartPlannerTests/
├── SmartPlannerUITests/
└── SmartPlanner/
    ├── App/             # запуск и навигация
    ├── UI/              # экраны, компоненты и ViewModel
    ├── Domain/          # бизнес-правила задач и статистики
    ├── Data/            # хранение задач
    ├── Network/         # HTTP-клиент и API endpoints
    ├── Repository/      # репозиторий новостей
    ├── Cache/           # кеш новостей и изображений
    ├── Models/
    ├── Services/
    └── DesignSystem/
```

### Android

```text
Android/app/src/main/java/com/example/smartplannercompose/
├── app/             # точка входа, навигация и DI-контейнер
├── core/            # общие инфраструктурные типы
├── domain/          # модели и бизнес-правила
├── data/            # SharedPreferences, сеть и файловый кеш
├── presentation/    # Compose-экраны и ViewModel
├── designsystem/    # общие UI-компоненты и токены
└── ui/theme/        # тема Material 3
```

## Данные и кеширование

Задачи сохраняются локально: iOS использует `UserDefaults`, Android —
`SharedPreferences`. Изменения передаются экранам через наблюдаемый
репозиторий.

Новости загружаются через NYTimes Top Stories API. В обеих версиях
используется локальный кеш:

- до 2 минут данные считаются свежими;
- после 2 минут кеш отображается сразу и обновляется в фоне;
- через 24 часа устаревший кеш удаляется.

## Настройка API

Получите ключ [NYTimes Top Stories API](https://developer.nytimes.com/docs/top-stories-product/1/overview).

Для iOS добавьте ключ в `iOS/SmartPlanner/Info.plist`:

```xml
<key>NYT_API_KEY</key>
<string>YOUR_API_KEY</string>
```

Для Android создайте `Android/local.properties` и добавьте:

```properties
NYT_API_KEY=YOUR_API_KEY
```

Также Android-ключ можно передать через переменную окружения `NYT_API_KEY`.
Файлы `local.properties` исключены из Git.

## Запуск iOS

Понадобятся Xcode 16.2 или новее и симулятор с iOS 17.6+.

1. Откройте `iOS/SmartPlanner.xcodeproj`.
2. Выберите схему `SmartPlanner` и iPhone Simulator.
3. Запустите приложение сочетанием `⌘R`.

## Запуск Android

Понадобятся Android Studio, JDK 17 и Android SDK 36.

1. Откройте папку `Android` в Android Studio.
2. Дождитесь завершения Gradle Sync.
3. Выберите эмулятор или устройство с API 24+.
4. Запустите конфигурацию `app`.

Сборка из терминала:

```bash
cd Android
./gradlew assembleDebug
```

## Тесты

iOS:

```bash
xcodebuild test \
  -project iOS/SmartPlanner.xcodeproj \
  -scheme SmartPlanner \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

Android:

```bash
cd Android
./gradlew test
```

В обеих реализациях покрыты доменная логика задач, статистика, ViewModel и
слой данных. Также присутствуют UI-тесты основного сценария создания задачи.

## Документация

- [ADR-1: доменные сервисы задач и репозиторий](docs/adr/ADR-1-task-domain-services-and-repository.md)
- [ADR-2: сеть, кеш и репозиторий новостей](docs/adr/ADR-2-news-network-cache-repository.md)
- [ADR-3: главный экран и статистика](docs/adr/ADR-3-dashboard-feature.md)
- [ADR-4: логические границы модулей](docs/adr/ADR-4-lightweight-module-boundaries.md)
