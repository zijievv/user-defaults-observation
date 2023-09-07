import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

// MARK: - Macro
public struct UserDefaultsObservationMacro: AccessorMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        let varDecl = try variableDecl(declaration)
        try noInitializer(with: varDecl)
        let (name, type) = try nameAndType(in: varDecl)
        let (arguments, exprs) = try argumentsExprs(from: node)
        let (keyExpr, defaultValueExpr) = try keyAndDefaultValue(in: exprs, arguments: arguments)
        let storeExpr = try userDefaultsExpr(of: exprs, in: arguments)
        return [
        #"""
get {
    access(keyPath: \.\#(raw: name))
    let store: UserDefaults = \#(storeExpr)
    return (store.value(forKey: \#(keyExpr)) as? \#(raw: type)) ?? \#(defaultValueExpr)
}
"""#,
        #"""
set {
    withMutation(keyPath: \.\#(raw: name)) {
        let store: UserDefaults = \#(storeExpr)
        store.set(newValue, forKey: \#(keyExpr))
    }
}
"""#,
        ]
    }

    private static func variableDecl(_ declaration: some DeclSyntaxProtocol) throws -> VariableDeclSyntax {
        guard let varDecl = declaration.as(VariableDeclSyntax.self), varDecl.bindingSpecifier.text == "var" else {
            throw DiagnosticsError(node: Syntax(declaration), message: .notVariableProperty)
        }
        return varDecl
    }

    private static func noInitializer(with varDecl: VariableDeclSyntax) throws {
        if let initializer = varDecl.bindings.first?.initializer {
            throw DiagnosticsError(node: Syntax(initializer), message: .cannotHaveInitialValue)
        }
    }

    private static func nameAndType(in varDecl: VariableDeclSyntax) throws -> (String, String) {
        guard let name = varDecl.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
            throw DiagnosticsError(node: Syntax(varDecl), message: .invalidPatternName)
        }
        guard let type = varDecl.bindings.first?.typeAnnotation?.type.as(IdentifierTypeSyntax.self)?.name.text else {
            throw DiagnosticsError(node: Syntax(varDecl), message: .invalidTypeAnnotation)
        }
        return (name, type)
    }

    private static func argumentsExprs(from node: AttributeSyntax) throws -> (LabeledExprListSyntax, [ExprSyntax?]) {
        guard
            let arguments = node.arguments?.as(LabeledExprListSyntax.self),
            let exprs = arguments.as(LabeledExprListSyntax.self)?.map({ $0.as(LabeledExprSyntax.self)?.expression }),
            exprs.count > 1
        else {
            throw DiagnosticsError(node: Syntax(node), message: .invalidAttributeArguments)
        }
        return (arguments, exprs)
    }

    private static func keyAndDefaultValue(
        in exprs: [ExprSyntax?],
        arguments: LabeledExprListSyntax
    ) throws -> (ExprSyntax, ExprSyntax) {
        guard let keyExpr = exprs[0] else {
            throw DiagnosticsError(node: Syntax(arguments[arguments.startIndex]), message: .invalidAttributeArguments)
        }
        guard let defaultValueExpr = exprs[1] else {
            let index = arguments.index(after: arguments.startIndex)
            throw DiagnosticsError(node: Syntax(arguments[index]), message: .invalidAttributeArguments)
        }
        return (keyExpr, defaultValueExpr)
    }

    private static func userDefaultsExpr(
        of exprs: [ExprSyntax?],
        in arguments: LabeledExprListSyntax
    ) throws -> ExprSyntax {
        if exprs.count > 2 {
            guard let storeExpr = exprs[2] else {
                let index = arguments.index(arguments.startIndex, offsetBy: 2)
                throw DiagnosticsError(node: Syntax(arguments[index]), message: .invalidAttributeArguments)
            }
            return storeExpr
        } else {
            return ".standard"
        }
    }
}

// MARK: - Diagnostics Error
enum UserDefaultsObservationMacrosDiagnostic: DiagnosticMessage {
    case notVariableProperty
    case cannotHaveInitialValue
    case invalidPatternName
    case invalidTypeAnnotation
    case invalidAttributeArguments

    var severity: DiagnosticSeverity { .error }

    var message: String {
        switch self {
        case .notVariableProperty:
            "Macro 'ObservableUserDefaults' is for variable properties only"
        case .cannotHaveInitialValue:
            "Variable with getter/setter cannot have an initial value"
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
        self.init(diagnostics: [
            .init(node: node, message: message)
        ])
    }
}

// MARK: - Plugin
@main
struct UserDefaultsObservationMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        UserDefaultsObservationMacro.self
    ]
}
