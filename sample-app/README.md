## Sample app MadSDK

Пример интеграции MadSDK в приложение. Более подробная интрукция находится [тут](https://mads-media.magnit.ru/docs/index.html)

1. Для генерации XCode проекта необходимо в папке sample-app вызвать:

```swift
tuist install && tuist generate
```


2. Для отображения тестовых креативов указывайте флаг:

```swift
MadsSDK.isDebugCreativeEnabled = true
```

3. В загрузчиках рекламы указывайте:

```swift
padId: 1
```
