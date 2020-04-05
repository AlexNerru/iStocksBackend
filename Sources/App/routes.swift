import Vapor

public func routes(_ router: Router) throws {
    router.get("istocks") { req in
        return "It works!"
    }
    
    let router = router.grouped("istocks")
    
    try router.register(collection: UsersController())
    let stocksController = StocksController()
    try router.register(collection: stocksController)
    try router.register(collection: AssetsController(stocksController: stocksController))
}
