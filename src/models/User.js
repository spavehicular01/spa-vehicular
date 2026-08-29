import mongoose from "mongoose";
import bcrypt from "bcryptjs";

const userSchema = new mongoose.Schema({
  Nombre: { type: String, required: true, uppercase: true, trim: true },
  Apellido: { type: String, required: true, uppercase: true, trim: true },
  telefono: { type: String, required: true, trim: true },
  Correo_Electronico: { type: String, required: true, unique: true, lowercase: true, trim: true },
  passwords: { type: String, required: true },

  // --- VERIFICACIÓN DE CUENTA ---
  isVerified: { type: Boolean, default: false },
  codigoVerificacion: { type: String },
  codigoVerificacionExpiracion: { type: Date },

  // Recuperación de contraseña
  codigoRecuperacion: { type: String },
  codigoexpiracion: { type: Date },

  rol: { type: String, enum: ["admin", "usuario"], default: "usuario" }
}, { timestamps: true });

// Encriptación antes de guardar
userSchema.pre("save", async function () {
  if (!this.isModified("passwords")) return;
  const salt = await bcrypt.genSalt(10);
  this.passwords = await bcrypt.hash(this.passwords, salt);
});

const User = mongoose.model("User", userSchema);

// IMPORTANTE: Asegúrate de tener esta línea al final
export default User;