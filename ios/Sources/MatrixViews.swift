import SwiftUI

struct MatrixRootView: View {
    @EnvironmentObject private var session: SessionStore
    var body: some View {
        ZStack {
            MatrixRain().opacity(0.20).ignoresSafeArea()
            switch session.state {
            case .welcome: WelcomeView()
            case .bootstrap: FounderBootstrapView()
            case .register: RegisterView()
            case .login: LoginView()
            case .locked: LocalLockView()
            case .home: HomeView()
            }
        }
        .background(Color.matrixBlack)
        .tint(.matrixGreen)
    }
}

struct WelcomeView: View {
    @EnvironmentObject private var session: SessionStore
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            MatrixIcon()
            Text("MATRIX").font(.system(size: 30, design: .monospaced)).tracking(8).foregroundStyle(.matrixGreen)
            Text("PROVA PRIVATA · DUE iPHONE").font(.caption.monospaced()).foregroundStyle(.matrixMuted)
            Button("CREA ACCOUNT") { session.state = .register }.buttonStyle(MatrixButtonStyle())
            Button("ACCEDI") { session.state = .login }.buttonStyle(.borderless).foregroundStyle(.matrixCyan)
            #if DEBUG
            Button("INIZIALIZZA GHOST / BLACK") { session.state = .bootstrap }
                .font(.caption.monospaced()).foregroundStyle(.matrixMuted)
            #endif
            Spacer()
        }.padding(28)
    }
}

struct FounderBootstrapView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var bootstrapCode = ""
    @State private var password = ""
    @State private var confirmation = ""
    @State private var localPin = ""
    var body: some View {
        NavigationStack {
            Form {
                Section("SOLO PRIMA INIZIALIZZAZIONE") {
                    Text("Crea l’unico fondatore Ghost / Black, al quale il database assegnerà E1.").font(.caption).foregroundStyle(.matrixMuted)
                    SecureField("Segreto monouso del backend", text: $bootstrapCode)
                    SecureField("Password Ghost / Black", text: $password)
                    SecureField("Conferma password", text: $confirmation)
                    SecureField("Codice locale 4–6 cifre", text: $localPin).keyboardType(.numberPad)
                }
                if let error = session.errorMessage { Text(error).foregroundStyle(.red) }
                Button("CREA FONDATORE") {
                    guard password == confirmation else { session.errorMessage = "Le password non corrispondono."; return }
                    Task { await session.bootstrapFounder(code: bootstrapCode, password: password, localPin: localPin) }
                }.disabled(bootstrapCode.isEmpty || password.count < 12 || password != confirmation || localPin.count < 4)
            }.scrollContentBackground(.hidden).navigationTitle("Bootstrap").toolbar { Button("Indietro") { session.state = .welcome } }
        }
    }
}

struct RegisterView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var displayName = ""
    @State private var username = ""
    @State private var password = ""
    @State private var confirmation = ""
    @State private var localPin = ""
    var body: some View {
        NavigationStack {
            Form {
                Section("NUOVA IDENTITÀ") {
                    TextField("Nome visibile", text: $displayName)
                    TextField("Username univoco", text: $username).textInputAutocapitalization(.never).autocorrectionDisabled()
                    SecureField("Password (almeno 12 caratteri)", text: $password)
                    SecureField("Conferma password", text: $confirmation)
                    SecureField("Codice locale (4–6 cifre)", text: $localPin).keyboardType(.numberPad)
                }
                Section { Text("Non vengono richiesti né memorizzati indirizzi email.").font(.caption).foregroundStyle(.matrixMuted) }
                if let error = session.errorMessage { Text(error).foregroundStyle(.red) }
                Button("CREA ACCOUNT") {
                    guard password == confirmation else { session.errorMessage = "Le password non corrispondono."; return }
                    Task { await session.register(displayName: displayName, username: username, password: password, localPin: localPin) }
                }.disabled(displayName.isEmpty || username.isEmpty || password.count < 12 || localPin.count < 4)
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("MATRIX")
            .toolbar { Button("Indietro") { session.state = .welcome } }
        }
    }
}

struct LoginView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var username = ""
    @State private var password = ""
    @State private var localPin = ""
    var body: some View {
        NavigationStack {
            Form {
                Section("ACCESSO") {
                    TextField("Username", text: $username).textInputAutocapitalization(.never).autocorrectionDisabled()
                    SecureField("Password", text: $password)
                    SecureField("Nuovo codice locale 4–6 cifre", text: $localPin).keyboardType(.numberPad)
                }
                if let error = session.errorMessage { Text(error).foregroundStyle(.red) }
                Button("ENTRA") { Task { await session.login(username: username, password: password, localPin: localPin) } }.disabled(username.isEmpty || password.isEmpty || localPin.count < 4)
            }.scrollContentBackground(.hidden).navigationTitle("MATRIX").toolbar { Button("Indietro") { session.state = .welcome } }
        }
    }
}

struct LocalLockView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var pin = ""
    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            MatrixIcon()
            Text("MATRIX BLOCCATO").font(.title3.monospaced()).foregroundStyle(.matrixGreen)
            SecureField("Codice locale", text: $pin).keyboardType(.numberPad).textFieldStyle(.roundedBorder).frame(maxWidth: 260)
            Button("SBLOCCA") { session.unlock(localPin: pin) }.buttonStyle(MatrixButtonStyle()).frame(maxWidth: 260)
            Text("Un codice errato elimina chiavi e sessione su questo iPhone.").font(.caption).foregroundStyle(.matrixMuted).multilineTextAlignment(.center).frame(maxWidth: 280)
            Spacer()
        }.padding()
    }
}

struct HomeView: View {
    @EnvironmentObject private var session: SessionStore
    var body: some View {
        TabView {
            ChatsPlaceholder().tabItem { Label("Chat", systemImage: "message") }
            DirectoryView().tabItem { Label("Trova", systemImage: "magnifyingglass") }
            RequestsPlaceholder().tabItem { Label("Richieste", systemImage: "person.badge.plus") }
            if session.session?.isFounder == true { AdminView().tabItem { Label("Admin", systemImage: "shield") } }
            ProfileView().tabItem { Label("Profilo", systemImage: "person") }
        }.task { if let token = session.session?.token { try? await MatrixAPI.shared.heartbeat(token: token) } }
    }
}

struct DirectoryView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var code = ""
    @State private var result: MatrixProfile?
    @State private var message: String?
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("Codice Matrix (es. E2)", text: $code).textInputAutocapitalization(.characters).textFieldStyle(.roundedBorder).padding(.horizontal)
                Button("CERCA") { Task { await find() } }.buttonStyle(MatrixButtonStyle()).padding(.horizontal)
                if let result { ProfileResult(profile: result, add: { Task { await request(result.publicCode) } }) }
                if let message { Text(message).font(.caption).foregroundStyle(.matrixMuted).multilineTextAlignment(.center).padding() }
                Spacer()
            }.padding(.top).navigationTitle("Trova")
        }
    }
    private func find() async {
        guard let token = session.session?.token else { return }
        do { result = try await MatrixAPI.shared.find(code: code, token: token); message = result == nil ? "Nessun account con questo codice." : nil }
        catch { message = error.localizedDescription }
    }
    private func request(_ code: String) async {
        guard let token = session.session?.token else { return }
        do { try await MatrixAPI.shared.requestFriend(code: code, token: token); message = "Richiesta inviata." }
        catch { message = error.localizedDescription }
    }
}

struct ProfileResult: View {
    let profile: MatrixProfile
    let add: () -> Void
    var body: some View {
        VStack(spacing: 7) {
            Text(profile.displayName).font(.title3.monospaced()).foregroundStyle(.matrixGreen)
            Text("@\(profile.username) · \(profile.publicCode) · \(profile.status)").font(.caption.monospaced()).foregroundStyle(.matrixMuted)
            Button("INVIA RICHIESTA", action: add).buttonStyle(MatrixButtonStyle())
        }.padding().overlay(Rectangle().stroke(.matrixGreen.opacity(0.6))).padding(.horizontal)
    }
}

struct ProfileView: View {
    @EnvironmentObject private var session: SessionStore
    var body: some View {
        NavigationStack {
            List {
                if let profile = session.session {
                    Section("IDENTITÀ") {
                        LabeledContent("Nome", value: profile.displayName)
                        LabeledContent("Username", value: "@\(profile.username)")
                        LabeledContent("Codice", value: profile.publicCode)
                    }
                }
                Section { Button("ESCI DAL DISPOSITIVO", role: .destructive) { session.resetLocalDevice() } }
            }.navigationTitle("Profilo")
        }
    }
}

struct ChatsPlaceholder: View { var body: some View { ContentUnavailableView("Chat cifrate", systemImage: "lock.fill", description: Text("Il relay è pronto. L’interfaccia chat verrà attivata dopo l’integrazione di un protocollo E2EE sottoposto ad audit.")) } }
struct RequestsPlaceholder: View { var body: some View { ContentUnavailableView("Richieste", systemImage: "person.badge.plus", description: Text("Le richieste ricevute saranno qui.")) } }

struct AdminView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var dashboard: DashboardOutput?
    @State private var error: String?
    var body: some View {
        NavigationStack {
            List {
                if let summary = dashboard?.summary { Section("STATO") { LabeledContent("Iscritti", value: "\(summary.registeredAccounts)"); LabeledContent("Online", value: "\(summary.onlineAccounts)"); LabeledContent("Disabilitati", value: "\(summary.disabledAccounts)") } }
                Section("ACCOUNT") { ForEach(dashboard?.accounts ?? []) { account in AccountRow(account: account) } }
                if let error { Text(error).foregroundStyle(.red) }
            }.navigationTitle("Admin").task { await load() }.refreshable { await load() }
        }
    }
    private func load() async { guard let token = session.session?.token else { return }; do { dashboard = try await MatrixAPI.shared.dashboard(token: token) } catch { self.error = error.localizedDescription } }
}

struct AccountRow: View {
    @EnvironmentObject private var session: SessionStore
    let account: AdminAccount
    var body: some View {
        HStack { VStack(alignment: .leading) { Text("\(account.displayName) · \(account.publicCode)"); Text("@\(account.username) · \(account.status)").font(.caption).foregroundStyle(.matrixMuted) }; Spacer(); if account.publicCode != "E1" { Menu("Azioni") { Button(account.disabledAt == nil ? "Disabilita" : "Riabilita") { Task { try? await MatrixAPI.shared.adminAction(code: account.publicCode, action: account.disabledAt == nil ? "disable" : "enable", token: session.session!.token) } }; Button("Revoca sessioni", role: .destructive) { Task { try? await MatrixAPI.shared.adminAction(code: account.publicCode, action: "revoke_sessions", token: session.session!.token) } } } } }
    }
}

struct MatrixIcon: View { var body: some View { Text("0101\n0110\n1001\n0101").font(.system(size: 17, design: .monospaced)).multilineTextAlignment(.center).foregroundStyle(.matrixGreen).frame(width: 116, height: 116).overlay(Rectangle().stroke(.matrixGreen)) } }
struct MatrixRain: View { var body: some View { GeometryReader { proxy in ForEach(0..<52, id: \.self) { i in Text((0..<38).map { _ in Bool.random() ? "1" : "0" }.joined(separator: "\n")).font(.system(size: 11, design: .monospaced)).foregroundStyle(.matrixGreen).opacity(0.4).position(x: CGFloat(i) * proxy.size.width / 51, y: proxy.size.height / 2) } } } }
struct MatrixButtonStyle: ButtonStyle { func makeBody(configuration: Configuration) -> some View { configuration.label.frame(maxWidth: .infinity).padding(13).foregroundStyle(Color.matrixGreen).background(Color.matrixGreen.opacity(configuration.isPressed ? 0.35 : 0.16)).overlay(Rectangle().stroke(Color.matrixGreen)) } }
extension Color { static let matrixGreen = Color(red: 0.39, green: 1, blue: 0.62); static let matrixCyan = Color(red: 0.44, green: 0.93, blue: 1); static let matrixMuted = Color(red: 0.53, green: 0.68, blue: 0.58); static let matrixBlack = Color(red: 0.01, green: 0.03, blue: 0.02) }
extension ShapeStyle where Self == Color {
    static var matrixGreen: Color {
        Color(red: 0.1, green: 1.0, blue: 0.3)
    }

    static var matrixMuted: Color {
        Color.gray
    }

    static var matrixCyan: Color {
        Color.cyan
    }
}
static var matrixCyan: Color {
    Color.cyan
}
