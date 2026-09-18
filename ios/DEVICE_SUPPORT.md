# Supporto iPhone fisico

Il progetto è configurato per compilare un'app iPhone solo per dispositivo:

- `SDKROOT = iphoneos`
- `SUPPORTED_PLATFORMS = iphoneos`
- `TARGETED_DEVICE_FAMILY = 1`
- `IPHONEOS_DEPLOYMENT_TARGET = 17.0`
- `PRODUCT_BUNDLE_IDENTIFIER = com.matrix.test`
- firma automatica di sviluppo attiva
- scheme condiviso: `MatrixTest.xcscheme`

Non è necessario installare un simulatore per compilare o installare su un iPhone fisico.

## Blocco attuale: Xcode 15.2 e iOS 26.5.2

Xcode 15.2 include l'SDK iOS 17.2. Non può riconoscere, abbinare e installare/debuggare su un iPhone con iOS 26.5.2. Il Deployment Target 17.0 indica la versione minima dell'app; non aggiorna il supporto dispositivo di Xcode.

Per iOS 26.5 Apple richiede una versione Xcode della generazione 26. Apple indica Xcode 26.6 per iOS 26.5 e richiede macOS Tahoe 26.2 o successivo. Un Mac su macOS Ventura 13.7.8 non può eseguire quella versione.

## Possibili strade

1. Usare un Mac compatibile con macOS Tahoe 26.2+ e Xcode 26.6+.
2. Usare un iPhone con una versione iOS supportata da Xcode 15.2.
3. Aggiornare il Mac a un macOS compatibile, se il modello di Mac è supportato.

Non esiste una modifica sicura a `.xcodeproj` che sostituisca il device-support mancante di Xcode.
