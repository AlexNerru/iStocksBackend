import Vapor

public func boot(_ app: Application) throws {
    print("[ BOOT ] Loading Quotes...")
    StocksController.loadStocks(app: app)
}
