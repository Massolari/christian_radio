var ye = (e, t, n) => {
  if (!t.has(e))
    throw TypeError("Cannot " + n);
};
var d = (e, t, n) => (ye(e, t, "read from private field"), n ? n.call(e) : t.get(e)), A = (e, t, n) => {
  if (t.has(e))
    throw TypeError("Cannot add the same private member more than once");
  t instanceof WeakSet ? t.add(e) : t.set(e, n);
}, h = (e, t, n, r) => (ye(e, t, "write to private field"), r ? r.call(e, n) : t.set(e, n), n);
var R = (e, t, n) => (ye(e, t, "access private method"), n);
class l {
  withFields(t) {
    let n = Object.keys(this).map(
      (r) => r in t ? t[r] : this[r]
    );
    return new this.constructor(...n);
  }
}
class fe {
  static fromArray(t, n) {
    let r = n || new Ce();
    for (let s = t.length - 1; s >= 0; --s)
      r = new Ke(t[s], r);
    return r;
  }
  [Symbol.iterator]() {
    return new ft(this);
  }
  toArray() {
    return [...this];
  }
  // @internal
  atLeastLength(t) {
    for (let n of this) {
      if (t <= 0)
        return !0;
      t--;
    }
    return t <= 0;
  }
  // @internal
  hasLength(t) {
    for (let n of this) {
      if (t <= 0)
        return !1;
      t--;
    }
    return t === 0;
  }
  countLength() {
    let t = 0;
    for (let n of this)
      t++;
    return t;
  }
}
function Oe(e, t) {
  return new Ke(e, t);
}
function c(e, t) {
  return fe.fromArray(e, t);
}
var H;
class ft {
  constructor(t) {
    A(this, H, void 0);
    h(this, H, t);
  }
  next() {
    if (d(this, H) instanceof Ce)
      return { done: !0 };
    {
      let { head: t, tail: n } = d(this, H);
      return h(this, H, n), { value: t, done: !1 };
    }
  }
}
H = new WeakMap();
class Ce extends fe {
}
class Ke extends fe {
  constructor(t, n) {
    super(), this.head = t, this.tail = n;
  }
}
class re {
  constructor(t) {
    if (!(t instanceof Uint8Array))
      throw "BitArray can only be constructed from a Uint8Array";
    this.buffer = t;
  }
  // @internal
  get length() {
    return this.buffer.length;
  }
  // @internal
  byteAt(t) {
    return this.buffer[t];
  }
  // @internal
  floatFromSlice(t, n, r) {
    return lt(this.buffer, t, n, r);
  }
  // @internal
  intFromSlice(t, n, r, s) {
    return ot(this.buffer, t, n, r, s);
  }
  // @internal
  binaryFromSlice(t, n) {
    return new re(this.buffer.slice(t, n));
  }
  // @internal
  sliceAfter(t) {
    return new re(this.buffer.slice(t));
  }
}
class ct {
  constructor(t) {
    this.value = t;
  }
}
function ot(e, t, n, r, s) {
  let i = 0;
  if (r)
    for (let u = t; u < n; u++)
      i = i * 256 + e[u];
  else
    for (let u = n - 1; u >= t; u--)
      i = i * 256 + e[u];
  if (s) {
    const a = 2 ** ((n - t) * 8 - 1);
    i >= a && (i -= a * 2);
  }
  return i;
}
function lt(e, t, n, r) {
  const s = new DataView(e.buffer), i = n - t;
  if (i === 8)
    return s.getFloat64(t, !r);
  if (i === 4)
    return s.getFloat32(t, !r);
  {
    const u = `Sized floats must be 32-bit or 64-bit on JavaScript, got size of ${i * 8} bits`;
    throw new globalThis.Error(u);
  }
}
class ce extends l {
  // @internal
  static isResult(t) {
    return t instanceof ce;
  }
}
class we extends ce {
  constructor(t) {
    super(), this[0] = t;
  }
  // @internal
  isOk() {
    return !0;
  }
}
class ge extends ce {
  constructor(t) {
    super(), this[0] = t;
  }
  // @internal
  isOk() {
    return !1;
  }
}
function D(e, t) {
  let n = [e, t];
  for (; n.length; ) {
    let r = n.pop(), s = n.pop();
    if (r === s)
      continue;
    if (!Be(r) || !Be(s) || !gt(r, s) || dt(r, s) || pt(r, s) || yt(r, s) || wt(r, s) || bt(r, s) || mt(r, s))
      return !1;
    const u = Object.getPrototypeOf(r);
    if (u !== null && typeof u.equals == "function")
      try {
        if (r.equals(s))
          continue;
        return !1;
      } catch {
      }
    let [a, o] = ht(r);
    for (let f of a(r))
      n.push(o(r, f), o(s, f));
  }
  return !0;
}
function ht(e) {
  if (e instanceof Map)
    return [(t) => t.keys(), (t, n) => t.get(n)];
  {
    let t = e instanceof globalThis.Error ? ["message"] : [];
    return [(n) => [...t, ...Object.keys(n)], (n, r) => n[r]];
  }
}
function dt(e, t) {
  return e instanceof Date && (e > t || e < t);
}
function pt(e, t) {
  return e.buffer instanceof ArrayBuffer && e.BYTES_PER_ELEMENT && !(e.byteLength === t.byteLength && e.every((n, r) => n === t[r]));
}
function yt(e, t) {
  return Array.isArray(e) && e.length !== t.length;
}
function wt(e, t) {
  return e instanceof Map && e.size !== t.size;
}
function bt(e, t) {
  return e instanceof Set && (e.size != t.size || [...e].some((n) => !t.has(n)));
}
function mt(e, t) {
  return e instanceof RegExp && (e.source !== t.source || e.flags !== t.flags);
}
function Be(e) {
  return typeof e == "object" && e !== null;
}
function gt(e, t) {
  return typeof e != "object" && typeof t != "object" && (!e || !t) || [Promise, WeakSet, WeakMap, Function].some((r) => e instanceof r) ? !1 : e.constructor === t.constructor;
}
function xt(e, t, n, r, s, i) {
  let u = new globalThis.Error(s);
  u.gleam_error = e, u.module = t, u.line = n, u.fn = r;
  for (let a in i)
    u[a] = i[a];
  return u;
}
class ve extends l {
  constructor(t) {
    super(), this[0] = t;
  }
}
class Ye extends l {
}
function At(e, t) {
  for (; ; ) {
    let n = e, r = t;
    if (n.hasLength(0))
      return r;
    {
      let s = n.head;
      e = n.tail, t = Oe(s, r);
    }
  }
}
function St(e) {
  return At(e, c([]));
}
function kt(e, t) {
  for (; ; ) {
    let n = e, r = t;
    if (n.hasLength(0))
      return !1;
    if (n.atLeastLength(1) && D(n.head, r))
      return n.head, !0;
    e = n.tail, t = r;
  }
}
function Et(e, t) {
  for (; ; ) {
    let n = e, r = t;
    if (n.hasLength(0))
      return r;
    {
      let s = n.head;
      e = n.tail, t = Oe(s, r);
    }
  }
}
function _t(e, t) {
  for (; ; ) {
    let n = e, r = t;
    if (n.hasLength(0))
      return St(r);
    {
      let s = n.head;
      e = n.tail, t = Et(s, r);
    }
  }
}
function Nt(e) {
  return _t(e, c([]));
}
function Ot(e) {
  return e;
}
const Re = /* @__PURE__ */ new WeakMap(), be = new DataView(new ArrayBuffer(8));
let me = 0;
function xe(e) {
  const t = Re.get(e);
  if (t !== void 0)
    return t;
  const n = me++;
  return me === 2147483647 && (me = 0), Re.set(e, n), n;
}
function Ae(e, t) {
  return e ^ t + 2654435769 + (e << 6) + (e >> 2) | 0;
}
function je(e) {
  let t = 0;
  const n = e.length;
  for (let r = 0; r < n; r++)
    t = Math.imul(31, t) + e.charCodeAt(r) | 0;
  return t;
}
function Xe(e) {
  be.setFloat64(0, e);
  const t = be.getInt32(0), n = be.getInt32(4);
  return Math.imul(73244475, t >> 16 ^ t) ^ n;
}
function jt(e) {
  return je(e.toString());
}
function zt(e) {
  const t = Object.getPrototypeOf(e);
  if (t !== null && typeof t.hashCode == "function")
    try {
      const r = e.hashCode(e);
      if (typeof r == "number")
        return r;
    } catch {
    }
  if (e instanceof Promise || e instanceof WeakSet || e instanceof WeakMap)
    return xe(e);
  if (e instanceof Date)
    return Xe(e.getTime());
  let n = 0;
  if (e instanceof ArrayBuffer && (e = new Uint8Array(e)), Array.isArray(e) || e instanceof Uint8Array)
    for (let r = 0; r < e.length; r++)
      n = Math.imul(31, n) + _(e[r]) | 0;
  else if (e instanceof Set)
    e.forEach((r) => {
      n = n + _(r) | 0;
    });
  else if (e instanceof Map)
    e.forEach((r, s) => {
      n = n + Ae(_(r), _(s)) | 0;
    });
  else {
    const r = Object.keys(e);
    for (let s = 0; s < r.length; s++) {
      const i = r[s], u = e[i];
      n = n + Ae(_(u), je(i)) | 0;
    }
  }
  return n;
}
function _(e) {
  if (e === null)
    return 1108378658;
  if (e === void 0)
    return 1108378659;
  if (e === !0)
    return 1108378657;
  if (e === !1)
    return 1108378656;
  switch (typeof e) {
    case "number":
      return Xe(e);
    case "string":
      return je(e);
    case "bigint":
      return jt(e);
    case "object":
      return zt(e);
    case "symbol":
      return xe(e);
    case "function":
      return xe(e);
    default:
      return 0;
  }
}
const T = 5, ze = Math.pow(2, T), $t = ze - 1, Tt = ze / 2, Mt = ze / 4, x = 0, $ = 1, k = 2, P = 3, $e = {
  type: k,
  bitmap: 0,
  array: []
};
function Q(e, t) {
  return e >>> t & $t;
}
function oe(e, t) {
  return 1 << Q(e, t);
}
function Lt(e) {
  return e -= e >> 1 & 1431655765, e = (e & 858993459) + (e >> 2 & 858993459), e = e + (e >> 4) & 252645135, e += e >> 8, e += e >> 16, e & 127;
}
function Te(e, t) {
  return Lt(e & t - 1);
}
function N(e, t, n) {
  const r = e.length, s = new Array(r);
  for (let i = 0; i < r; ++i)
    s[i] = e[i];
  return s[t] = n, s;
}
function It(e, t, n) {
  const r = e.length, s = new Array(r + 1);
  let i = 0, u = 0;
  for (; i < t; )
    s[u++] = e[i++];
  for (s[u++] = n; i < r; )
    s[u++] = e[i++];
  return s;
}
function Se(e, t) {
  const n = e.length, r = new Array(n - 1);
  let s = 0, i = 0;
  for (; s < t; )
    r[i++] = e[s++];
  for (++s; s < n; )
    r[i++] = e[s++];
  return r;
}
function Je(e, t, n, r, s, i) {
  const u = _(t);
  if (u === r)
    return {
      type: P,
      hash: u,
      array: [
        { type: x, k: t, v: n },
        { type: x, k: s, v: i }
      ]
    };
  const a = { val: !1 };
  return ee(
    Me($e, e, u, t, n, a),
    e,
    r,
    s,
    i,
    a
  );
}
function ee(e, t, n, r, s, i) {
  switch (e.type) {
    case $:
      return Ft(e, t, n, r, s, i);
    case k:
      return Me(e, t, n, r, s, i);
    case P:
      return qt(e, t, n, r, s, i);
  }
}
function Ft(e, t, n, r, s, i) {
  const u = Q(n, t), a = e.array[u];
  if (a === void 0)
    return i.val = !0, {
      type: $,
      size: e.size + 1,
      array: N(e.array, u, { type: x, k: r, v: s })
    };
  if (a.type === x)
    return D(r, a.k) ? s === a.v ? e : {
      type: $,
      size: e.size,
      array: N(e.array, u, {
        type: x,
        k: r,
        v: s
      })
    } : (i.val = !0, {
      type: $,
      size: e.size,
      array: N(
        e.array,
        u,
        Je(t + T, a.k, a.v, n, r, s)
      )
    });
  const o = ee(a, t + T, n, r, s, i);
  return o === a ? e : {
    type: $,
    size: e.size,
    array: N(e.array, u, o)
  };
}
function Me(e, t, n, r, s, i) {
  const u = oe(n, t), a = Te(e.bitmap, u);
  if (e.bitmap & u) {
    const o = e.array[a];
    if (o.type !== x) {
      const p = ee(o, t + T, n, r, s, i);
      return p === o ? e : {
        type: k,
        bitmap: e.bitmap,
        array: N(e.array, a, p)
      };
    }
    const f = o.k;
    return D(r, f) ? s === o.v ? e : {
      type: k,
      bitmap: e.bitmap,
      array: N(e.array, a, {
        type: x,
        k: r,
        v: s
      })
    } : (i.val = !0, {
      type: k,
      bitmap: e.bitmap,
      array: N(
        e.array,
        a,
        Je(t + T, f, o.v, n, r, s)
      )
    });
  } else {
    const o = e.array.length;
    if (o >= Tt) {
      const f = new Array(32), p = Q(n, t);
      f[p] = Me($e, t + T, n, r, s, i);
      let b = 0, S = e.bitmap;
      for (let m = 0; m < 32; m++) {
        if (S & 1) {
          const J = e.array[b++];
          f[m] = J;
        }
        S = S >>> 1;
      }
      return {
        type: $,
        size: o + 1,
        array: f
      };
    } else {
      const f = It(e.array, a, {
        type: x,
        k: r,
        v: s
      });
      return i.val = !0, {
        type: k,
        bitmap: e.bitmap | u,
        array: f
      };
    }
  }
}
function qt(e, t, n, r, s, i) {
  if (n === e.hash) {
    const u = Le(e, r);
    if (u !== -1)
      return e.array[u].v === s ? e : {
        type: P,
        hash: n,
        array: N(e.array, u, { type: x, k: r, v: s })
      };
    const a = e.array.length;
    return i.val = !0, {
      type: P,
      hash: n,
      array: N(e.array, a, { type: x, k: r, v: s })
    };
  }
  return ee(
    {
      type: k,
      bitmap: oe(e.hash, t),
      array: [e]
    },
    t,
    n,
    r,
    s,
    i
  );
}
function Le(e, t) {
  const n = e.array.length;
  for (let r = 0; r < n; r++)
    if (D(t, e.array[r].k))
      return r;
  return -1;
}
function se(e, t, n, r) {
  switch (e.type) {
    case $:
      return Dt(e, t, n, r);
    case k:
      return Bt(e, t, n, r);
    case P:
      return Rt(e, r);
  }
}
function Dt(e, t, n, r) {
  const s = Q(n, t), i = e.array[s];
  if (i !== void 0) {
    if (i.type !== x)
      return se(i, t + T, n, r);
    if (D(r, i.k))
      return i;
  }
}
function Bt(e, t, n, r) {
  const s = oe(n, t);
  if (!(e.bitmap & s))
    return;
  const i = Te(e.bitmap, s), u = e.array[i];
  if (u.type !== x)
    return se(u, t + T, n, r);
  if (D(r, u.k))
    return u;
}
function Rt(e, t) {
  const n = Le(e, t);
  if (!(n < 0))
    return e.array[n];
}
function Ie(e, t, n, r) {
  switch (e.type) {
    case $:
      return Ht(e, t, n, r);
    case k:
      return Ut(e, t, n, r);
    case P:
      return Pt(e, r);
  }
}
function Ht(e, t, n, r) {
  const s = Q(n, t), i = e.array[s];
  if (i === void 0)
    return e;
  let u;
  if (i.type === x) {
    if (!D(i.k, r))
      return e;
  } else if (u = Ie(i, t + T, n, r), u === i)
    return e;
  if (u === void 0) {
    if (e.size <= Mt) {
      const a = e.array, o = new Array(e.size - 1);
      let f = 0, p = 0, b = 0;
      for (; f < s; ) {
        const S = a[f];
        S !== void 0 && (o[p] = S, b |= 1 << f, ++p), ++f;
      }
      for (++f; f < a.length; ) {
        const S = a[f];
        S !== void 0 && (o[p] = S, b |= 1 << f, ++p), ++f;
      }
      return {
        type: k,
        bitmap: b,
        array: o
      };
    }
    return {
      type: $,
      size: e.size - 1,
      array: N(e.array, s, u)
    };
  }
  return {
    type: $,
    size: e.size,
    array: N(e.array, s, u)
  };
}
function Ut(e, t, n, r) {
  const s = oe(n, t);
  if (!(e.bitmap & s))
    return e;
  const i = Te(e.bitmap, s), u = e.array[i];
  if (u.type !== x) {
    const a = Ie(u, t + T, n, r);
    return a === u ? e : a !== void 0 ? {
      type: k,
      bitmap: e.bitmap,
      array: N(e.array, i, a)
    } : e.bitmap === s ? void 0 : {
      type: k,
      bitmap: e.bitmap ^ s,
      array: Se(e.array, i)
    };
  }
  return D(r, u.k) ? e.bitmap === s ? void 0 : {
    type: k,
    bitmap: e.bitmap ^ s,
    array: Se(e.array, i)
  } : e;
}
function Pt(e, t) {
  const n = Le(e, t);
  if (n < 0)
    return e;
  if (e.array.length !== 1)
    return {
      type: P,
      hash: e.hash,
      array: Se(e.array, n)
    };
}
function Ve(e, t) {
  if (e === void 0)
    return;
  const n = e.array, r = n.length;
  for (let s = 0; s < r; s++) {
    const i = n[s];
    if (i !== void 0) {
      if (i.type === x) {
        t(i.v, i.k);
        continue;
      }
      Ve(i, t);
    }
  }
}
class M {
  /**
   * @template V
   * @param {Record<string,V>} o
   * @returns {Dict<string,V>}
   */
  static fromObject(t) {
    const n = Object.keys(t);
    let r = M.new();
    for (let s = 0; s < n.length; s++) {
      const i = n[s];
      r = r.set(i, t[i]);
    }
    return r;
  }
  /**
   * @template K,V
   * @param {Map<K,V>} o
   * @returns {Dict<K,V>}
   */
  static fromMap(t) {
    let n = M.new();
    return t.forEach((r, s) => {
      n = n.set(s, r);
    }), n;
  }
  static new() {
    return new M(void 0, 0);
  }
  /**
   * @param {undefined | Node<K,V>} root
   * @param {number} size
   */
  constructor(t, n) {
    this.root = t, this.size = n;
  }
  /**
   * @template NotFound
   * @param {K} key
   * @param {NotFound} notFound
   * @returns {NotFound | V}
   */
  get(t, n) {
    if (this.root === void 0)
      return n;
    const r = se(this.root, 0, _(t), t);
    return r === void 0 ? n : r.v;
  }
  /**
   * @param {K} key
   * @param {V} val
   * @returns {Dict<K,V>}
   */
  set(t, n) {
    const r = { val: !1 }, s = this.root === void 0 ? $e : this.root, i = ee(s, 0, _(t), t, n, r);
    return i === this.root ? this : new M(i, r.val ? this.size + 1 : this.size);
  }
  /**
   * @param {K} key
   * @returns {Dict<K,V>}
   */
  delete(t) {
    if (this.root === void 0)
      return this;
    const n = Ie(this.root, 0, _(t), t);
    return n === this.root ? this : n === void 0 ? M.new() : new M(n, this.size - 1);
  }
  /**
   * @param {K} key
   * @returns {boolean}
   */
  has(t) {
    return this.root === void 0 ? !1 : se(this.root, 0, _(t), t) !== void 0;
  }
  /**
   * @returns {[K,V][]}
   */
  entries() {
    if (this.root === void 0)
      return [];
    const t = [];
    return this.forEach((n, r) => t.push([r, n])), t;
  }
  /**
   *
   * @param {(val:V,key:K)=>void} fn
   */
  forEach(t) {
    Ve(this.root, t);
  }
  hashCode() {
    let t = 0;
    return this.forEach((n, r) => {
      t = t + Ae(_(n), _(r)) | 0;
    }), t;
  }
  /**
   * @param {unknown} o
   * @returns {boolean}
   */
  equals(t) {
    if (!(t instanceof M) || this.size !== t.size)
      return !1;
    let n = !0;
    return this.forEach((r, s) => {
      n = n && D(t.get(s, !r), r);
    }), n;
  }
}
function q(e) {
  const t = typeof e;
  if (e === !0)
    return "True";
  if (e === !1)
    return "False";
  if (e === null)
    return "//js(null)";
  if (e === void 0)
    return "Nil";
  if (t === "string")
    return Wt(e);
  if (t === "bigint" || t === "number")
    return e.toString();
  if (Array.isArray(e))
    return `#(${e.map(q).join(", ")})`;
  if (e instanceof fe)
    return Yt(e);
  if (e instanceof ct)
    return Jt(e);
  if (e instanceof re)
    return Xt(e);
  if (e instanceof l)
    return vt(e);
  if (e instanceof M)
    return Ct(e);
  if (e instanceof Set)
    return `//js(Set(${[...e].map(q).join(", ")}))`;
  if (e instanceof RegExp)
    return `//js(${e})`;
  if (e instanceof Date)
    return `//js(Date("${e.toISOString()}"))`;
  if (e instanceof Function) {
    const n = [];
    for (const r of Array(e.length).keys())
      n.push(String.fromCharCode(r + 97));
    return `//fn(${n.join(", ")}) { ... }`;
  }
  return Kt(e);
}
function Wt(e) {
  let t = '"';
  for (let n = 0; n < e.length; n++) {
    let r = e[n];
    switch (r) {
      case `
`:
        t += "\\n";
        break;
      case "\r":
        t += "\\r";
        break;
      case "	":
        t += "\\t";
        break;
      case "\f":
        t += "\\f";
        break;
      case "\\":
        t += "\\\\";
        break;
      case '"':
        t += '\\"';
        break;
      default:
        r < " " || r > "~" && r < " " ? t += "\\u{" + r.charCodeAt(0).toString(16).toUpperCase().padStart(4, "0") + "}" : t += r;
    }
  }
  return t += '"', t;
}
function Ct(e) {
  let t = "dict.from_list([", n = !0;
  return e.forEach((r, s) => {
    n || (t = t + ", "), t = t + "#(" + q(s) + ", " + q(r) + ")", n = !1;
  }), t + "])";
}
function Kt(e) {
  var i, u;
  const t = ((u = (i = Object.getPrototypeOf(e)) == null ? void 0 : i.constructor) == null ? void 0 : u.name) || "Object", n = [];
  for (const a of Object.keys(e))
    n.push(`${q(a)}: ${q(e[a])}`);
  const r = n.length ? " " + n.join(", ") + " " : "";
  return `//js(${t === "Object" ? "" : t + " "}{${r}})`;
}
function vt(e) {
  const t = Object.keys(e).map((n) => {
    const r = q(e[n]);
    return isNaN(parseInt(n)) ? `${n}: ${r}` : r;
  }).join(", ");
  return t ? `${e.constructor.name}(${t})` : e.constructor.name;
}
function Yt(e) {
  return `[${e.toArray().map(q).join(", ")}]`;
}
function Xt(e) {
  return `<<${Array.from(e.buffer).join(", ")}>>`;
}
function Jt(e) {
  return `//utfcodepoint(${String.fromCodePoint(e.value)})`;
}
function Vt(e) {
  let t = q(e);
  return Ot(t);
}
function Gt(e, t, n) {
  return e ? t : n();
}
class Zt extends l {
  constructor(t) {
    super(), this.all = t;
  }
}
function Ge() {
  return new Zt(c([]));
}
class Qt extends l {
  constructor(t) {
    super(), this.content = t;
  }
}
class g extends l {
  constructor(t, n, r, s, i, u, a) {
    super(), this.key = t, this.namespace = n, this.tag = r, this.attrs = s, this.children = i, this.self_closing = u, this.void = a;
  }
}
class Ze extends l {
  constructor(t, n, r) {
    super(), this[0] = t, this[1] = n, this.as_property = r;
  }
}
function en(e, t) {
  return new Ze(e, t, !1);
}
function tn(e, t) {
  return new Ze(e, t, !0);
}
function j(e) {
  return en("class", e);
}
function nn(e) {
  return tn("disabled", e);
}
function le(e, t, n) {
  return e === "area" ? new g("", "", e, t, c([]), !1, !0) : e === "base" ? new g("", "", e, t, c([]), !1, !0) : e === "br" ? new g("", "", e, t, c([]), !1, !0) : e === "col" ? new g("", "", e, t, c([]), !1, !0) : e === "embed" ? new g("", "", e, t, c([]), !1, !0) : e === "hr" ? new g("", "", e, t, c([]), !1, !0) : e === "img" ? new g("", "", e, t, c([]), !1, !0) : e === "input" ? new g("", "", e, t, c([]), !1, !0) : e === "link" ? new g("", "", e, t, c([]), !1, !0) : e === "meta" ? new g("", "", e, t, c([]), !1, !0) : e === "param" ? new g("", "", e, t, c([]), !1, !0) : e === "source" ? new g("", "", e, t, c([]), !1, !0) : e === "track" ? new g("", "", e, t, c([]), !1, !0) : e === "wbr" ? new g("", "", e, t, c([]), !1, !0) : new g("", "", e, t, n, !1, !1);
}
function Y(e) {
  return new Qt(e);
}
class rn extends l {
  constructor(t) {
    super(), this[0] = t;
  }
}
class te extends l {
  constructor(t) {
    super(), this[0] = t;
  }
}
class sn extends l {
}
class un extends l {
  constructor(t) {
    super(), this[0] = t;
  }
}
function He(e, t, n, r = !1) {
  let s, i = [{ prev: e, next: t, parent: e.parentNode }];
  for (; i.length; ) {
    let { prev: u, next: a, parent: o } = i.pop();
    if (a.subtree !== void 0 && (a = a.subtree()), a.content !== void 0)
      if (u)
        if (u.nodeType === Node.TEXT_NODE)
          u.textContent !== a.content && (u.textContent = a.content), s ?? (s = u);
        else {
          const f = document.createTextNode(a.content);
          o.replaceChild(f, u), s ?? (s = f);
        }
      else {
        const f = document.createTextNode(a.content);
        o.appendChild(f), s ?? (s = f);
      }
    else if (a.tag !== void 0) {
      const f = an({
        prev: u,
        next: a,
        dispatch: n,
        stack: i,
        isComponent: r
      });
      u ? u !== f && o.replaceChild(f, u) : o.appendChild(f), s ?? (s = f);
    } else
      a.elements !== void 0 ? X(a, (f) => {
        i.unshift({ prev: u, next: f, parent: o }), u = u == null ? void 0 : u.nextSibling;
      }) : a.subtree !== void 0 && i.push({ prev: u, next: a, parent: o });
  }
  return s;
}
function an({ prev: e, next: t, dispatch: n, stack: r }) {
  const s = t.namespace || "http://www.w3.org/1999/xhtml", i = e && e.nodeType === Node.ELEMENT_NODE && e.localName === t.tag && e.namespaceURI === (t.namespace || "http://www.w3.org/1999/xhtml"), u = i ? e : s ? document.createElementNS(s, t.tag) : document.createElement(t.tag);
  let a;
  if (V.has(u))
    a = V.get(u);
  else {
    const w = /* @__PURE__ */ new Map();
    V.set(u, w), a = w;
  }
  const o = i ? new Set(a.keys()) : null, f = i ? new Set(Array.from(e.attributes, (w) => w.name)) : null;
  let p = null, b = null, S = null;
  for (const w of t.attrs) {
    const y = w[0], E = w[1];
    if (w.as_property)
      u[y] !== E && (u[y] = E), i && f.delete(y);
    else if (y.startsWith("on")) {
      const B = y.slice(2), pe = n(E);
      a.has(B) || u.addEventListener(B, G), a.set(B, pe), i && o.delete(B);
    } else if (y.startsWith("data-lustre-on-")) {
      const B = y.slice(15), pe = n(fn);
      a.has(B) || u.addEventListener(B, G), a.set(B, pe), u.setAttribute(y, E);
    } else
      y === "class" ? p = p === null ? E : p + " " + E : y === "style" ? b = b === null ? E : b + E : y === "dangerous-unescaped-html" ? S = E : (u.getAttribute(y) !== E && u.setAttribute(y, E), (y === "value" || y === "selected") && (u[y] = E), i && f.delete(y));
  }
  if (p !== null && (u.setAttribute("class", p), i && f.delete("class")), b !== null && (u.setAttribute("style", b), i && f.delete("style")), i) {
    for (const w of f)
      u.removeAttribute(w);
    for (const w of o)
      a.delete(w), u.removeEventListener(w, G);
  }
  if (t.key !== void 0 && t.key !== "")
    u.setAttribute("data-lustre-key", t.key);
  else if (S !== null)
    return u.innerHTML = S, u;
  let m = u.firstChild, J = null, qe = null, De = null, de = t.children[Symbol.iterator]().next().value;
  i && de !== void 0 && // Explicit checks are more verbose but truthy checks force a bunch of comparisons
  // we don't care about: it's never gonna be a number etc.
  de.key !== void 0 && de.key !== "" && (J = /* @__PURE__ */ new Set(), qe = Ue(e), De = Ue(t));
  for (const w of t.children)
    X(w, (y) => {
      y.key !== void 0 && J !== null ? m = cn(
        m,
        y,
        u,
        r,
        De,
        qe,
        J
      ) : (r.unshift({ prev: m, next: y, parent: u }), m = m == null ? void 0 : m.nextSibling);
    });
  for (; m; ) {
    const w = m.nextSibling;
    u.removeChild(m), m = w;
  }
  return u;
}
const V = /* @__PURE__ */ new WeakMap();
function G(e) {
  const t = e.currentTarget;
  if (!V.has(t)) {
    t.removeEventListener(e.type, G);
    return;
  }
  const n = V.get(t);
  if (!n.has(e.type)) {
    t.removeEventListener(e.type, G);
    return;
  }
  n.get(e.type)(e);
}
function fn(e) {
  const t = e.currentTarget, n = t.getAttribute(`data-lustre-on-${e.type}`), r = JSON.parse(t.getAttribute("data-lustre-data") || "{}"), s = JSON.parse(t.getAttribute("data-lustre-include") || "[]");
  switch (e.type) {
    case "input":
    case "change":
      s.push("target.value");
      break;
  }
  return {
    tag: n,
    data: s.reduce(
      (i, u) => {
        var o;
        const a = u.split(".");
        for (let f = 0, p = i, b = e; f < a.length; f++)
          f === a.length - 1 ? p[a[f]] = b[a[f]] : (p[o = a[f]] ?? (p[o] = {}), b = b[a[f]], p = p[a[f]]);
        return i;
      },
      { data: r }
    )
  };
}
function Ue(e) {
  const t = /* @__PURE__ */ new Map();
  if (e)
    for (const n of e.children)
      X(n, (r) => {
        var i;
        const s = (r == null ? void 0 : r.key) || ((i = r == null ? void 0 : r.getAttribute) == null ? void 0 : i.call(r, "data-lustre-key"));
        s && t.set(s, r);
      });
  return t;
}
function cn(e, t, n, r, s, i, u) {
  for (; e && !s.has(e.getAttribute("data-lustre-key")); ) {
    const o = e.nextSibling;
    n.removeChild(e), e = o;
  }
  if (i.size === 0)
    return X(t, (o) => {
      r.unshift({ prev: e, next: o, parent: n }), e = e == null ? void 0 : e.nextSibling;
    }), e;
  if (u.has(t.key))
    return console.warn(`Duplicate key found in Lustre vnode: ${t.key}`), r.unshift({ prev: null, next: t, parent: n }), e;
  u.add(t.key);
  const a = i.get(t.key);
  if (!a && !e)
    return r.unshift({ prev: null, next: t, parent: n }), e;
  if (!a && e !== null) {
    const o = document.createTextNode("");
    return n.insertBefore(o, e), r.unshift({ prev: o, next: t, parent: n }), e;
  }
  return !a || a === e ? (r.unshift({ prev: e, next: t, parent: n }), e = e == null ? void 0 : e.nextSibling, e) : (n.insertBefore(a, e), r.unshift({ prev: a, next: t, parent: n }), e);
}
function X(e, t) {
  if (e.elements !== void 0)
    for (const n of e.elements)
      X(n, t);
  else
    e.subtree !== void 0 ? X(e.subtree(), t) : t(e);
}
var O, L, z, I, C, F, K, U, v, ne, Z, Ee, ue, Qe, ae, et;
const Fe = class Fe {
  constructor([t, n], r, s, i = document.body, u = !1) {
    A(this, v);
    A(this, Z);
    A(this, ue);
    A(this, ae);
    A(this, O, null);
    A(this, L, []);
    A(this, z, []);
    A(this, I, !1);
    A(this, C, !1);
    A(this, F, null);
    A(this, K, null);
    A(this, U, null);
    h(this, F, t), h(this, K, r), h(this, U, s), h(this, O, i), h(this, z, n.all.toArray()), h(this, I, !0), h(this, C, u), window.requestAnimationFrame(() => R(this, v, ne).call(this));
  }
  static start(t, n, r, s, i) {
    if (!tt())
      return new ge(new nt());
    const u = n instanceof HTMLElement ? n : document.querySelector(n);
    if (!u)
      return new ge(new hn(n));
    const a = new Fe(r(t), s, i, u);
    return new we((o) => a.send(o));
  }
  send(t) {
    switch (!0) {
      case t instanceof te: {
        d(this, L).push(t[0]), R(this, v, ne).call(this);
        return;
      }
      case t instanceof sn: {
        R(this, ae, et).call(this);
        return;
      }
      case t instanceof rn: {
        R(this, ue, Qe).call(this, t[0]);
        return;
      }
      default:
        return;
    }
  }
  emit(t, n) {
    d(this, O).dispatchEvent(
      new CustomEvent(t, {
        bubbles: !0,
        detail: n,
        composed: !0
      })
    );
  }
};
O = new WeakMap(), L = new WeakMap(), z = new WeakMap(), I = new WeakMap(), C = new WeakMap(), F = new WeakMap(), K = new WeakMap(), U = new WeakMap(), v = new WeakSet(), ne = function() {
  if (R(this, Z, Ee).call(this), d(this, I)) {
    const t = d(this, U).call(this, d(this, F)), n = (r) => (s) => {
      const i = r(s);
      i instanceof we && this.send(new te(i[0]));
    };
    h(this, I, !1), h(this, O, He(d(this, O), t, n, d(this, C)));
  }
}, Z = new WeakSet(), Ee = function(t = 0) {
  for (; d(this, L).length; ) {
    const [n, r] = d(this, K).call(this, d(this, F), d(this, L).shift());
    d(this, I) || h(this, I, d(this, F) !== n), h(this, F, n), h(this, z, d(this, z).concat(r.all.toArray()));
  }
  for (; d(this, z).length; )
    d(this, z).shift()(
      (n) => this.send(new te(n)),
      (n, r) => this.emit(n, r)
    );
  d(this, L).length && (t < 5 ? R(this, Z, Ee).call(this, ++t) : window.requestAnimationFrame(() => R(this, v, ne).call(this)));
}, ue = new WeakSet(), Qe = function(t) {
  switch (!0) {
    case t instanceof un: {
      const n = d(this, U).call(this, t[0]), r = (s) => (i) => {
        const u = s(i);
        u instanceof we && this.send(new te(u[0]));
      };
      h(this, L, []), h(this, z, []), h(this, I, !1), h(this, O, He(d(this, O), n, r, d(this, C)));
    }
  }
}, ae = new WeakSet(), et = function() {
  d(this, O).remove(), h(this, O, null), h(this, F, null), h(this, L, []), h(this, z, []), h(this, I, !1), h(this, K, () => {
  }), h(this, U, () => {
  });
};
let ke = Fe;
const on = (e, t, n) => ke.start(
  n,
  t,
  e.init,
  e.update,
  e.view
), tt = () => globalThis.window && window.document;
class ln extends l {
  constructor(t, n, r, s) {
    super(), this.init = t, this.update = n, this.view = r, this.on_attribute_change = s;
  }
}
class hn extends l {
  constructor(t) {
    super(), this.selector = t;
  }
}
class nt extends l {
}
function dn(e, t, n) {
  return new ln(e, t, n, new Ye());
}
function pn(e, t, n) {
  return Gt(
    !tt(),
    new ge(new nt()),
    () => on(e, t, n)
  );
}
function yn(e, t) {
  return le("main", e, t);
}
function W(e, t) {
  return le("div", e, t);
}
function _e(e, t) {
  return le("span", e, t);
}
function rt(e, t) {
  return le("button", e, t);
}
class ie extends l {
}
class Ne extends l {
}
class Pe extends l {
  constructor(t) {
    super(), this[0] = t;
  }
}
class he extends l {
  constructor(t) {
    super(), this[0] = t;
  }
}
function wn(e, t) {
  if (e instanceof ie)
    return new ie();
  if (e instanceof Ne)
    return new Ne();
  if (e instanceof Pe) {
    let n = e[0];
    return new Pe(n);
  } else {
    let n = e[0];
    return new he(t(n));
  }
}
function bn(e, t) {
  return e instanceof he ? e[0] : t;
}
function mn(e) {
  if (e instanceof he) {
    let t = e[0];
    return new ve(t);
  } else
    return new Ye();
}
class gn extends l {
  constructor(t, n) {
    super(), this.title = t, this.artist = n;
  }
}
class xn extends l {
}
class An extends l {
}
class st extends l {
}
class it extends l {
}
class Sn extends l {
}
class kn extends l {
}
class ut extends l {
}
function En(e) {
  return e instanceof xn ? "data_saver_off" : e instanceof An ? "error" : e instanceof st ? "favorite" : e instanceof it ? "favorite_border" : e instanceof Sn ? "heart_broken" : e instanceof kn ? "music_off" : e instanceof ut ? "play_arrow" : "sync_problem";
}
function at(e, t) {
  let n = En(t);
  return _e(
    Oe(j("material-icons"), e),
    c([Y(n)])
  );
}
function We(e) {
  return W(
    c([j("flex flex-col gap-1")]),
    c([
      _e(
        c([j("text-dark-shades text-lg font-medium")]),
        c([Y(e.title)])
      ),
      _e(
        c([j("text-dark-accent text-sm italic")]),
        c([Y(e.artist)])
      )
    ])
  );
}
function _n(e, t) {
  let n = mn(e);
  if (n instanceof ve) {
    let r = n[0];
    return rt(
      c([]),
      c([
        at(
          c([j("text-3xl")]),
          kt(t, r) ? new st() : new it()
        )
      ])
    );
  } else
    return Y("");
}
function Nn(e) {
  return rt(
    Nt(
      c([
        (() => {
          let n = wn(e, (r) => c([]));
          return bn(
            n,
            c([j("opacity-50"), nn(!0)])
          );
        })(),
        c([j("flex items-center gap-2")])
      ])
    ),
    c([at(c([j("text-4xl")]), new ut())])
  );
}
function On(e, t) {
  return W(
    c([j("absolute w-full bottom-2 px-1 h-20")]),
    c([
      W(
        c([
          j(
            "w-full h-full bg-light-shades rounded-lg flex justify-between px-5 py-3 items-center"
          )
        ]),
        c([
          (() => {
            if (e instanceof ie)
              return W(
                c([]),
                c([Y("Nenhuma estação selecionada")])
              );
            if (e instanceof Ne)
              return W(c([]), c([Y("Carregando...")]));
            if (e instanceof he) {
              let n = e[0];
              return We(n);
            } else {
              let n = e[0];
              return We(
                new gn("Erro ao carregar música", Vt(n))
              );
            }
          })(),
          W(
            c([]),
            c([
              _n(e, t),
              Nn(e)
            ])
          )
        ])
      )
    ])
  );
}
class jn extends l {
  constructor(t, n, r, s) {
    super(), this.tab = t, this.song = n, this.history = r, this.favorites = s;
  }
}
class zn extends l {
}
function $n(e) {
  return [
    new jn(new zn(), new ie(), c([]), c([])),
    Ge()
  ];
}
function Tn(e, t) {
  {
    let n = t.tab;
    return [e.withFields({ tab: n }), Ge()];
  }
}
function Mn(e) {
  return yn(
    c([j("bg-main-brand flex flex-col gap-8 pt-6 h-screen")]),
    c([On(e.song, e.favorites)])
  );
}
function In() {
  let e = dn($n, Tn, Mn), t = pn(e, "#app", void 0);
  if (!t.isOk())
    throw xt(
      "assignment_no_match",
      "client",
      257,
      "main",
      "Assignment pattern did not match",
      { value: t }
    );
}
export {
  In as main
};
