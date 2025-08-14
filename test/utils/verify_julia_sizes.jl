using Glaze

println("Julia struct sizes and offsets:\n")

println("ConcreteTypeDescriptor:")
println("  sizeof: ", sizeof(Glaze.ConcreteTypeDescriptor))
println("  index offset: ", fieldoffset(Glaze.ConcreteTypeDescriptor, 1))
println("  data offset: ", fieldoffset(Glaze.ConcreteTypeDescriptor, 2))

println("\nStructDesc:")
println("  sizeof: ", sizeof(Glaze.StructDesc))
println("  type_name offset: ", fieldoffset(Glaze.StructDesc, 1))
println("  info offset: ", fieldoffset(Glaze.StructDesc, 2))
println("  type_hash offset: ", fieldoffset(Glaze.StructDesc, 3))

println("\nMemberInfo:")
println("  sizeof: ", sizeof(Glaze.MemberInfo))
println("  name offset: ", fieldoffset(Glaze.MemberInfo, 1))
println("  type offset: ", fieldoffset(Glaze.MemberInfo, 2))
println("  getter offset: ", fieldoffset(Glaze.MemberInfo, 3))
println("  setter offset: ", fieldoffset(Glaze.MemberInfo, 4))

# Check individual descriptor sizes
println("\nDescriptor component sizes:")
println("  PrimitiveDesc: ", sizeof(Glaze.PrimitiveDesc))
println("  StringDesc: ", sizeof(Glaze.StringDesc))
println("  VectorDesc: ", sizeof(Glaze.VectorDesc))
println("  MapDesc: ", sizeof(Glaze.MapDesc))
println("  ComplexDesc: ", sizeof(Glaze.ComplexDesc))
println("  StructDesc: ", sizeof(Glaze.StructDesc))

# Verify sizes match C++
println("\nVerification:")
if sizeof(Glaze.ConcreteTypeDescriptor) == 40
    println("✓ ConcreteTypeDescriptor size matches C++ (40 bytes)")
else
    println("✗ ConcreteTypeDescriptor size mismatch! Julia: $(sizeof(Glaze.ConcreteTypeDescriptor)), C++: 40")
end

if sizeof(Glaze.StructDesc) == 24
    println("✓ StructDesc size matches C++ (24 bytes)")
else
    println("✗ StructDesc size mismatch! Julia: $(sizeof(Glaze.StructDesc)), C++: 24")
end

if sizeof(Glaze.MemberInfo) == 48
    println("✓ MemberInfo size matches C++ (48 bytes)")
else
    println("✗ MemberInfo size mismatch! Julia: $(sizeof(Glaze.MemberInfo)), C++: 48")
end