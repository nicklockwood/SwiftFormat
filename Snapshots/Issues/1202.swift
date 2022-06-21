// swiftformat:disable wrapArguments,wrapMultilineStatementBraces

private final class FadeTransitionStyle: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using _: UIViewControllerContextTransitioning?) -> TimeInterval {
        0.3
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from),
              let toVC = transitionContext.viewController(forKey: .to) else { return }

        toVC.view.alpha = 0
        UIView.transition(
            with: transitionContext.containerView,
            duration: transitionDuration(using: transitionContext),
            options: []) {
                fromVC.view.alpha = 0
                transitionContext.containerView.addSubview(toVC.view)
                toVC.view.frame = transitionContext.finalFrame(for: toVC)
                toVC.view.alpha = 1
            } completion: { _ in
                transitionContext.completeTransition(true)
                fromVC.view.removeFromSuperview()
            }
    }
}
