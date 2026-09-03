import mongoose from "mongoose";
import bcrypt from "bcryptjs";

const userSchema = new mongoose.Schema({
  // Nombres (sombra/compatibilidad)
  nombres: { type: String, trim: true },
  Nombre: { type: String, uppercase: true, trim: true },

  // Apellidos (sombra/compatibilidad)
  apellidos: { type: String, trim: true },
  Apellido: { type: String, uppercase: true, trim: true },

  // Teléfono / Celular
  celular: { type: String, trim: true },
  telefono: { type: String, trim: true },

  // Documento de identidad
  documentoIdentidad: { type: String, trim: true },

  // Correos con índice disperso (sparse) para evitar duplicados en campos nulos
  correo: { 
    type: String, 
    lowercase: true, 
    trim: true, 
    sparse: true 
  },
  Correo_Electronico: { 
    type: String, 
    lowercase: true, 
    trim: true, 
    sparse: true 
  },

  // Contraseñas
  password: { type: String },
  passwords: { type: String },

  // --- VERIFICACIÓN DE CUENTA ---
  isVerified: { type: Boolean, default: false },
  codigoVerificacion: { type: String, default: null },
  codigoVerif: { type: String, default: null },
  codigoVerificacionExpiracion: { type: Date, default: null },
  codigoVerificacionExpira: { type: Date, default: null },

  // --- RECUPERACIÓN DE CONTRASEÑA ---
  resetPasswordCode: { type: String, default: null },
  resetPasswordExpires: { type: Date, default: null },
  codigoRecuperacion: { type: String, default: null },
  codigoRecuperacionExpiracion: { type: Date, default: null },

  // Roles compatibles
  rol: { 
    type: String, 
    enum: ["admin", "usuario", "cliente", "ADMIN", "USUARIO", "CLIENTE"], 
    default: "usuario" 
  }
}, { timestamps: true });

// Middleware asíncrono sin 'next'
userSchema.pre("save", async function () {
  // Si la contraseña en 'password' fue modificada y no está hasheada
  if (this.isModified("password") && this.password && !this.password.startsWith("$2b$")) {
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
  }

  // Si la contraseña en 'passwords' fue modificada y no está hasheada
  if (this.isModified("passwords") && this.passwords && !this.passwords.startsWith("$2b$")) {
    const salt = await bcrypt.genSalt(10);
    this.passwords = await bcrypt.hash(this.passwords, salt);
  }
});

const User = mongoose.model("User", userSchema);

export default User;