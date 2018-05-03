import Foundation

public class ForPIso {}
public typealias PIsoOf<S, T, A, B> = Kind4<ForPIso, S, T, A, B>
public typealias PIsoPartial<S, T, A> = Kind3<ForPIso, S, T, A>

public typealias Iso<S, A> = PIso<S, S, A, A>
public typealias ForIso = ForPIso
public typealias IsoOf<S, A> = PIsoOf<S, S, A, A>
public typealias IsoPartial<S> = Kind<ForIso, S>

public class PIso<S, T, A, B> : PIsoOf<S, T, A, B> {
    private let getFunc : (S) -> A
    private let reverseGetFunc : (B) -> T
    
    public static func +<C, D>(lhs : PIso<S, T, A, B>, rhs : PIso<A, B, C, D>) -> PIso<S, T, C, D> {
        return lhs.compose(rhs)
    }
    
    public static func +<C>(lhs : PIso<S, T, A, B>, rhs : Getter<A, C>) -> Getter<S, C> {
        return lhs.compose(rhs)
    }
    
    public init(get : @escaping (S) -> A, reverseGet : @escaping (B) -> T) {
        self.getFunc = get
        self.reverseGetFunc = reverseGet
    }
    
    public func get(_ s : S) -> A {
        return getFunc(s)
    }
    
    public func reverseGet(_ b : B) -> T {
        return reverseGetFunc(b)
    }
    
    public func mapping<Func, F>(_ functor : Func) -> PIso<Kind<F, S>, Kind<F, T>, Kind<F, A>, Kind<F, B>> where Func : Functor, Func.F == F {
        return PIso<Kind<F, S>, Kind<F, T>, Kind<F, A>, Kind<F, B>>(get: { fs in
            functor.map(fs, self.get)
        }, reverseGet: { fb in
            functor.map(fb, self.reverseGet)
        })
    }
    
    public func modifyF<Func, F>(_ functor : Func, _ s : S, _ f : @escaping (A) -> Kind<F, B>) -> Kind<F, T> where Func : Functor, Func.F == F {
        return functor.map(f(get(s)), self.reverseGet)
    }
    
    public func liftF<Func, F>(_ functor : Func, _ f : @escaping (A) -> Kind<F, B>) -> (S) -> Kind<F, T> where Func : Functor, Func.F == F {
        return { s in
            functor.map(f(self.get(s)), self.reverseGet)
        }
    }
    
    public func reverse() -> PIso<B, A, T, S> {
        return PIso<B, A, T, S>(get: self.reverseGet, reverseGet: self.get)
    }
    
    public func find(_ s : S, _ predicate : (A) -> Bool) -> Maybe<A> {
        let a = get(s)
        return predicate(a) ? Maybe.some(a) : Maybe.none()
    }
    
    public func set(_ b : B) -> T {
        return reverseGet(b)
    }
    
    public func split<S1, T1, A1, B1>(_ other : PIso<S1, T1, A1, B1>) -> PIso<(S, S1), (T, T1), (A, A1), (B, B1)> {
        return PIso<(S, S1), (T, T1), (A, A1), (B, B1)>(
            get: { (s, s1) in (self.get(s), other.get(s1)) },
            reverseGet: { (b, b1) in (self.reverseGet(b), other.reverseGet(b1)) })
    }
    
    public func first<C>() -> PIso<(S, C), (T, C), (A, C), (B, C)> {
        return PIso<(S, C), (T, C), (A, C), (B, C)>(
            get: { (s, c) in (self.get(s), c) },
            reverseGet: { (b, c) in (self.reverseGet(b), c) })
    }
    
    public func second<C>() -> PIso<(C, S), (C, T), (C, A), (C, B)> {
        return PIso<(C, S), (C, T), (C, A), (C, B)>(
            get: { (c, s) in (c, self.get(s)) },
            reverseGet: { (c, b) in (c, self.reverseGet(b)) })
    }
    
    public func left<C>() -> PIso<Either<S, C>, Either<T, C>, Either<A, C>, Either<B, C>> {
        return PIso<Either<S, C>, Either<T, C>, Either<A, C>, Either<B, C>>(
            get: { either in either.bimap(self.get, id) },
            reverseGet: { either in either.bimap(self.reverseGet, id) })
    }
    
    public func right<C>() -> PIso<Either<C, S>, Either<C, T>, Either<C, A>, Either<C, B>> {
        return PIso<Either<C, S>, Either<C, T>, Either<C, A>, Either<C, B>>(
            get: { either in either.bimap(id, self.get) },
            reverseGet: { either in either.bimap(id, self.reverseGet) })
    }
    
    public func compose<C, D>(_ other : PIso<A, B, C, D>) -> PIso<S, T, C, D> {
        return PIso<S, T, C, D>(get: self.get >>> other.get, reverseGet: other.reverseGet >>> self.reverseGet)
    }
    
    public func compose<C>(_ other : Getter<A, C>) -> Getter<S, C> {
        return self.asGetter().compose(other)
    }
    
    public func asGetter() -> Getter<S, A> {
        return Getter(get : self.get)
    }
    
    public func asLens() -> PLens<S, T, A, B> {
        return PLens(get: self.get, set: { _, b in self.set(b) })
    }
    
    public func asPrism() -> PPrism<S, T, A, B> {
        return PPrism(getOrModify: { s in Either.right(self.get(s)) }, reverseGet: self.reverseGet)
    }
    
    public func exists(_ s : S, _ predicate : (A) -> Bool) -> Bool {
        return predicate(get(s))
    }
    
    public func modify(_ s : S, _ f : @escaping (A) -> B) -> T {
        return reverseGet(f(get(s)))
    }
    
    public func lift(_ f : @escaping (A) -> B) -> (S) -> T {
        return { s in self.modify(s, f) }
    }
}


















