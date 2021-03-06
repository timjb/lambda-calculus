
module Lambda.ClosedTerms where

open import Data.Empty
open import Data.Nat
open import Data.Nat.Properties
open import Relation.Binary hiding (nonEmpty)
open import Relation.Binary.PropositionalEquality
open import Relation.Nullary

open import Lambda.Core

data Closed′ (n : ℕ) : Term → Set where
  ctvar : ∀ {v} → v < n → Closed′ n (tvar v)
  ctapp : ∀ {t₁ t₂} → Closed′ n t₁ → Closed′ n t₂ → Closed′ n (tapp t₁ t₂)
  ctabs : ∀ {t} → Closed′ (suc n) t → Closed′ n (tabs t)

closed-incr : ∀ {n} {t} i → Closed′ n t → Closed′ (n + i) t
closed-incr {n} {tvar x} i (ctvar x<n) = ctvar (≤-trans x<n (m≤m+n n i))
  where open DecTotalOrder decTotalOrder renaming (trans to ≤-trans)
closed-incr {n} {tapp t₁ t₂} i (ctapp ct₁ ct₂) = ctapp (closed-incr i ct₁) (closed-incr i ct₂)
closed-incr {n} {tabs t} i (ctabs ct) = ctabs (closed-incr i ct)

Closed : Term → Set
Closed t = Closed′ 0 t

<-irreflexive : ∀ n → ¬ (n < n)
<-irreflexive 0 ()
<-irreflexive (suc n) ssn≤sn = <-irreflexive n (≤-pred ssn≤sn)

<⇒≢ : ∀ n m → n < m → n ≢ m
<⇒≢ n m n<m n≡m rewrite sym n≡m = <-irreflexive n n<m

closed′-subst : ∀ {n} t s v → Closed′ n t → n ≤ v → t [ v ≔ s ] ≡ t
closed′-subst (tvar x) s v (ctvar x<n) n≤v with v ≟ x
... | yes v≡x = ⊥-elim (<⇒≢ x v (≤-trans x<n n≤v) (sym v≡x))
  where open DecTotalOrder decTotalOrder renaming (trans to ≤-trans)
... | no  _   = refl
closed′-subst (tapp t₁ t₂) s v (ctapp ct₁ ct₂) n≤v = cong₂ tapp (closed′-subst t₁ s v ct₁ n≤v) (closed′-subst t₂ s v ct₂ n≤v)
closed′-subst (tabs t) s v (ctabs ct) n≤v = cong tabs (closed′-subst t (shift 1 0 s) (suc v) ct (s≤s n≤v))

closed-subst : ∀ t s v → Closed t → t [ v ≔ s ] ≡ t
closed-subst t s v closed = closed′-subst t s v closed z≤n

closed′-shift : ∀ {n} t d c → Closed′ n t → n ≤ c → shift d c t ≡ t
closed′-shift (tvar x) d c (ctvar x<n) n≤c with c ≤? x
... | yes c≤x = ⊥-elim (<-irreflexive x (≤-trans x<n (≤-trans n≤c c≤x)))
  where open DecTotalOrder decTotalOrder renaming (trans to ≤-trans)
... | no  _   = refl
closed′-shift (tapp t₁ t₂) d c (ctapp ct₁ ct₂) n≤c = cong₂ tapp (closed′-shift t₁ d c ct₁ n≤c) (closed′-shift t₂ d c ct₂ n≤c)
closed′-shift (tabs t) d c (ctabs ct) n≤c = cong tabs (closed′-shift t d (suc c) ct (s≤s n≤c))

closed-shift : ∀ t d c → Closed t → shift d c t ≡ t
closed-shift t d c closed = closed′-shift t d c closed z≤n

closed′-unshift : ∀ {n} t d c → Closed′ n t → n ≤ c → unshift d c t ≡ t
closed′-unshift (tvar x) d c (ctvar x<n) n≤c with c ≤? x
... | yes c≤x = ⊥-elim (<-irreflexive x (≤-trans x<n (≤-trans n≤c c≤x)))
  where open DecTotalOrder decTotalOrder renaming (trans to ≤-trans)
... | no  _   = refl
closed′-unshift (tapp t₁ t₂) d c (ctapp ct₁ ct₂) n≤c = cong₂ tapp (closed′-unshift t₁ d c ct₁ n≤c) (closed′-unshift t₂ d c ct₂ n≤c)
closed′-unshift (tabs t) d c (ctabs ct) n≤c = cong tabs (closed′-unshift t d (suc c) ct (s≤s n≤c))

closed-unshift : ∀ t d c → Closed t → unshift d c t ≡ t
closed-unshift t d c closed = closed′-unshift t d c closed z≤n

beta-closed : Term → ℕ → Term → Term
beta-closed (tvar x) v s with v ≟ x
... | yes p = s
... | no  p = unshift 1 v (tvar x)
beta-closed (tapp t₁ t₂) v s = tapp (beta-closed t₁ v s) (beta-closed t₂ v s)
beta-closed (tabs t) v s = tabs (beta-closed t (suc v) s)

beta-closed-unshift-subst : ∀ t s v → Closed s → unshift 1 v (t [ v ≔ s ]) ≡ beta-closed t v s
beta-closed-unshift-subst (tvar x) s v c with v ≟ x
... | yes v≡x = closed-unshift s 1 v c
... | no  v≢x = refl
beta-closed-unshift-subst (tapp t₁ t₂) s v c = cong₂ tapp (beta-closed-unshift-subst t₁ s v c) (beta-closed-unshift-subst t₂ s v c)
beta-closed-unshift-subst (tabs t) s v c = cong tabs (trans (cong (unshift 1 (suc v)) (cong (_[_≔_] t (suc v)) (closed-shift s 1 0 c)))
                                                            (beta-closed-unshift-subst t s (suc v) c))

→βbeta-closed : ∀ {t} {s} → Closed s → tapp (tabs t) s →β beta-closed t 0 s
→βbeta-closed {t} {s} c rewrite sym (trans (cong (unshift 1 0) (cong (_[_≔_] t 0) (closed-shift s 1 0 c))) (beta-closed-unshift-subst t s 0 c)) = →βbeta

closed′-beta-closed : ∀ {n} t v s → Closed′ n t → n ≤ v → beta-closed t v s ≡ t
closed′-beta-closed (tvar x) v s (ctvar x<n) n≤v with v ≟ x
... | yes v≡x = ⊥-elim (<⇒≢ x v (≤-trans x<n n≤v) (sym v≡x))
  where open DecTotalOrder decTotalOrder renaming (trans to ≤-trans)
... | no  p = closed′-unshift (tvar x) 1 v (ctvar x<n) n≤v
closed′-beta-closed (tapp t₁ t₂) v s (ctapp ct₁ ct₂) n≤v = cong₂ tapp (closed′-beta-closed t₁ v s ct₁ n≤v) (closed′-beta-closed t₂ v s ct₂ n≤v)
closed′-beta-closed (tabs t) v s (ctabs ct) n≤v = cong tabs (closed′-beta-closed t (suc v) s ct (s≤s n≤v))

closed-beta-closed : ∀ t v s → Closed t → beta-closed t v s ≡ t
closed-beta-closed t v s c = closed′-beta-closed t v s c z≤n