public struct DataChangedNotificationPayload: NotificationPayload {
    private enum UserInfoKey: String {
        case insertedObjects
        case updatedObjects
        case deletedObjects
    }

    public let insertedObjects: [NSManagedObject]
    public let updatedObjects: [NSManagedObject]
    public let deletedObjects: [NSManagedObject]

    public init?(userInfo: [AnyHashable: Any]?) {
        if
            let insertedObjects = userInfo?[UserInfoKey.insertedObjects] as? [NSManagedObject],
            let updatedObjects = userInfo?[UserInfoKey.updatedObjects] as? [NSManagedObject],
            let deletedObjects = userInfo?[UserInfoKey.deletedObjects] as? [NSManagedObject]
        {
            self.insertedObjects = insertedObjects
            self.updatedObjects = updatedObjects
            self.deletedObjects = deletedObjects
        } else {
            return nil
        }
    }
}
