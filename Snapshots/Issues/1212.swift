// swiftformat:disable all

func getType(_ _type: ClassifyType, _ t1: Double? = nil, _ t2: Double? = nil) -> (type: ClassifyType, roots: [Double]?) { var type = _type if let t1 = t1 { var t1Ok = t1 > 0 && t1 < 1 var t2Ok = t2 == nil ? false : (t2! > 0 && t2! < 1) if (!(t1Ok || t2Ok) || type == .loop && !(t1Ok && t2Ok)) { type = .arch t1Ok = false t2Ok = false } let roots: [Double]? = t1Ok || t2Ok ? t1Ok && t2Ok ? t1 < t2! ? [t1, t2!] : [t2!, t1] : [t1Ok ? t1 : t2!] : nil return (type, roots) } else { return (type, nil) } }
