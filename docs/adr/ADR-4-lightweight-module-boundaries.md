# ADR-4: Lightweight module boundaries вместо физического выноса Core

## Статус

Accepted

## Контекст

В проекте уже выделен доменный слой (см. ADR-1, ADR-3). Хотелось усилить требование по модульности: вынести Core/Domain в отдельный Swift Package или framework target, чтобы зависимости были запечены компилятором, а не держались на честном слове.

Перед защитой нужно было трезво оценить — стоит ли это делать сейчас или ограничиться логическими границами.

## Решение

**Перед защитой физический перенос не делается.** Все Core/Domain типы остаются в основном app target `SmartPlanner`. Модульность держится на:

1. **Структуре папок.** Внутри `SmartPlanner/` уже три параллельных слоя:
   ```
   Domain/Tasks/        — Task, TaskFilter, TaskSortOption, TaskValidator,
                          CreateTaskUseCase, TaskListProcessor
   Domain/Dashboard/    — DashboardPeriod, DashboardStatistics,
                          DashboardStatisticsService
   Data/Tasks/          — TaskRepositoryProtocol, InMemoryTaskRepository
   UI/                  — все ViewController, View, ViewModel
   DesignSystem/        — DesignTokens, DashboardPalette
   ```
2. **Направлении зависимостей.** На уровне импортов это соблюдается:
   - `UI → Domain` и `UI → Data` (через протоколы).
   - `Data → Domain` (репозиторий знает о `Task`, домен о репозитории не знает).
   - `Domain` импортирует только `Foundation`. Никакого `UIKit` внутри Domain нет.

   UIKit-расширения над доменными типами (например, `TaskPriority.tintColor`, `TaskPriority.identifierSuffix`) живут не в Domain, а в файлах UI-компонентов — Swift это позволяет, и доменный enum остаётся чистым.

3. **Внедрении зависимостей через протоколы.** `TaskListProcessing`, `TaskRepositoryProtocol`, `CreateTaskUseCaseProtocol`, `DashboardStatisticsServicing`, `TaskValidating`. Все ViewModel принимают их в init — это позволяет подменять реализации в тестах без модульного барьера.

### Что было бы нужно для физического выноса

Если после защиты понадобится сделать `SmartPlannerCore` отдельным local Swift Package:

1. Создать папку `SmartPlannerCore/` с `Package.swift` и подпапкой `Sources/SmartPlannerCore/`.
2. Перенести туда:
   - `Domain/Tasks/Task.swift` (только модель и `TaskPriority`)
   - `Domain/Tasks/TaskFilter.swift`
   - `Domain/Tasks/TaskValidator.swift`
   - `Domain/Tasks/CreateTaskUseCase.swift`
   - `Domain/Tasks/TaskListProcessor.swift`
   - `Domain/Dashboard/*` (все три файла)
   - `Data/Tasks/TaskRepository.swift` — только протокол `TaskRepositoryProtocol`, реализация `InMemoryTaskRepository` остаётся в app
3. Сделать все типы и их API `public`, включая explicit `public init` у `Task` и `CreateTaskInput` (синтезируемые init у public struct остаются internal).
4. Убрать дефолтные аргументы вида `repository: TaskRepositoryProtocol = InMemoryTaskRepository.shared` из use case и ViewModel — Core не может ссылаться на app-реализацию. Все 6 точек вызова (`CreateTaskUseCase`, `TasksViewModel`, `CreateTaskViewModel`, `DashboardViewModel`, `DayTasksViewModel` + само создание use case в `CreateTaskViewModel`) переходят на явный DI в app-коде.
5. Добавить `import SmartPlannerCore` во все UI-файлы, которые ссылаются на доменные типы.
6. В тестах заменить `@testable import SmartPlanner` на `@testable import SmartPlannerCore` для Core-тестов либо использовать обычный `import SmartPlannerCore` через public API.
7. Подключить пакет к app target через "Add Package Dependency → Add Local..." и `Frameworks, Libraries`.
8. Прогнать unit + UI тесты, проверить `-UITests` launch arg (он сейчас работает через `UserDefaults` ключ `SmartPlanner.tasks.v1` — этот контракт сохраняется).

## Последствия

**Плюсы текущего решения.**
- Перед защитой не вносим риск массовой правки `public`/`init`/pbxproj. Проект продолжает собираться так же, как собирался.
- Логические границы зафиксированы в коде и в этом ADR, любой ревьюер видит, что они соблюдаются: UI/Data зависят от Domain, Domain ни от чего внешнего не зависит.
- Все 90 unit-тестов и UI happy-path остаются стабильными.
- При переезде на Swift Package в будущем правки сосредоточены в Domain-файлах + точках DI, UI не трогается принципиально.

**Минусы и ограничения.**
- Границы держатся на дисциплине разработчика, не на компиляторе. Случайно импортировать `UIKit` в файле Domain — синтаксически ничего не запретит. Сейчас этого нет, но проверять надо вручную.
- `InMemoryTaskRepository.shared` сейчас тянется как дефолт в нескольких ViewModel — это удобно, но прячет граф зависимостей. Без физического разделения легко "не заметить", что VM держит зависимость на конкретную реализацию.
- Pbxproj со схемой `PBXFileSystemSynchronizedRootGroup` (Xcode 16+) делает добавление нового таргета/пакета менее предсказуемым — это дополнительная причина не трогать перед защитой.
- Студенческий проект, есть жёсткий дедлайн — поэтому компромисс осознанный.
