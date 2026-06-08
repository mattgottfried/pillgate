import ManagedSettings
import ManagedSettingsUI
import UIKit

class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        makeConfiguration()
    }

    override func configuration(shielding application: Application,
                                in webDomain: WebDomain) -> ShieldConfiguration {
        makeConfiguration()
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        makeConfiguration()
    }

    private func makeConfiguration() -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: UIColor.systemBackground,
            icon: UIImage(systemName: "pill.fill"),
            title: ShieldConfiguration.Label(
                text: "Time for your medication",
                color: .label
            ),
            subtitle: ShieldConfiguration.Label(
                text: "Open IoniqOS to take a photo and unlock your phone.",
                color: .secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Open IoniqOS",
                color: .white
            ),
            primaryButtonBackgroundColor: .systemBlue
        )
    }
}
