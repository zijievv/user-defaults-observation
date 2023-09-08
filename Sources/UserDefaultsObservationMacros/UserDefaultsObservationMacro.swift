import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct UserDefaultsObservationMacro {}

// MARK: - Peer Macro
extension UserDefaultsObservationMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let varDecl = try variableDecl(declaration)
        let name = try name(from: varDecl)
        let type = try type(from: varDecl)
        let statement: DeclSyntax = if let initializer = varDecl.bindings.first?.initializer {
            "@ObservationIgnored private var _\(raw: name): \(raw: type) \(initializer)"
        } else {
            "@ObservationIgnored private var _\(raw: name): \(raw: type)"
        }
        return [statement]
    }
}

extension UserDefaultsObservationMacro {
    private static func variableDecl(_ declaration: some DeclSyntaxProtocol) throws -> VariableDeclSyntax {
        guard let varDecl = declaration.as(VariableDeclSyntax.self), varDecl.bindingSpecifier.text == "var" else {
            throw DiagnosticsError(node: Syntax(declaration), message: .notVariableProperty)
        }
        return varDecl
    }

    private static func name(from varDecl: VariableDeclSyntax) throws -> String {
        guard let name = varDecl.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
            throw DiagnosticsError(node: Syntax(varDecl), message: .invalidPatternName)
        }
        return name
    }

    private static func type(from varDecl: VariableDeclSyntax) throws -> String {
        guard let type = varDecl.bindings.first?.typeAnnotation?.type.as(IdentifierTypeSyntax.self)?.name.text else {
            throw DiagnosticsError(node: Syntax(varDecl), message: .invalidTypeAnnotation)
        }
        return type
    }
}

// MARK: - Accessor Macro
extension UserDefaultsObservationMacro: AccessorMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        let varDecl = try variableDecl(declaration)
        let name = try name(from: varDecl)
        let type = try type(from: varDecl)
        let arguments = try arguments(from: node)
        let keyExpr = try keyExpr(from: arguments)
        let storeExpr = try userDefaultsExpr(from: arguments)
        return [
            #"""
@storageRestrictions(initializes: _\#(raw: name))
init(initialValue) {
    _\#(raw: name) = initialValue
}
"""#,
            #"""
get {
    access(keyPath: \.\#(raw: name))
    let store: UserDefaults = \#(storeExpr)
    _\#(raw: name) = (store.value(forKey: \#(keyExpr)) as? \#(raw: type)) ?? _\#(raw: name)
    return _\#(raw: name)
}
"""#,
            #"""
set {
    withMutation(keyPath: \.\#(raw: name)) {
        let store: UserDefaults = \#(storeExpr)
        _\#(raw: name) = newValue
        store.set(_\#(raw: name), forKey: \#(keyExpr))
    }
}
"""#,
        ]
    }

    private static func arguments(from node: AttributeSyntax) throws -> LabeledExprListSyntax {
        guard let args = node.arguments?.as(LabeledExprListSyntax.self) else {
            throw DiagnosticsError(node: Syntax(node), message: .invalidAttributeArguments)
        }
        return args
    }

    private static func keyExpr(from arguments: LabeledExprListSyntax) throws -> ExprSyntax {
        guard let expr = arguments.first?.as(LabeledExprSyntax.self)?.expression else {
            throw DiagnosticsError(node: Syntax(arguments), message: .invalidAttributeArguments)
        }
        return expr
    }

    private static func userDefaultsExpr(from arguments: LabeledExprListSyntax) throws -> ExprSyntax {
        guard arguments.count > 1 else { return ".standard" }
        let index = arguments.index(after: arguments.startIndex)
        guard let expr = arguments[index].as(LabeledExprSyntax.self)?.expression else {
            throw DiagnosticsError(node: Syntax(arguments[index]), message: .invalidAttributeArguments)
        }
        return expr
    }
}

// MARK: - Diagnostics Error
enum UserDefaultsObservationMacrosDiagnostic: DiagnosticMessage {
    case notVariableProperty
    case invalidPatternName
    case invalidTypeAnnotation
    case invalidAttributeArguments

    var severity: DiagnosticSeverity { .error }

    var message: String {
        switch self {
        case .notVariableProperty:
            "Macro 'ObservableUserDefaults' is for variable properties only"
        case .invalidPatternName:
            "Invalid pattern"
        case .invalidTypeAnnotation:
            "Required valid type annotation in pattern"
        case .invalidAttributeArguments:
            "Invalid arguments"
        }
    }

    var diagnosticID: MessageID { .init(domain: "UserDefaultsObservationMacro", id: self.message) }
}

extension DiagnosticsError {
    fileprivate init(node: Syntax, message: UserDefaultsObservationMacrosDiagnostic) {
        self.init(diagnostics: [.init(node: node, message: message)])
    }
}

// MARK: - Plugin
@main
struct UserDefaultsObservationMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        UserDefaultsObservationMacro.self
    ]
}
