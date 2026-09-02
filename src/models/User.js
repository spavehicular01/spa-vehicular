import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';

// 1. Definición del esquema
const userSchema = new mongoose.Schema({
  nombres: { type: String, required: true },
  correo: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  rol: { 
    type: String, 
    enum: ['cliente', 'administrador', 'operario'], 
    default: 'cliente' 
  },
  direccionPrincipal: { type: String, default: '' },

  // --- VERIFICACIÓN DE CUENTA ---
  isVerified: { type: Boolean, default: false },
  codigoVerificacion: { type: String },
  codigoVerificacionExpiracion: { type: Date },

  // --- RECUPERACIÓN DE CONTRASEÑA ---
  codigoRecuperacion: { type: String },
  codigoexpiracion: { type: Date }
}, { timestamps: true });

// 2. Encriptación de contraseña antes de guardar
userSchema.pre("save", async function () {
  if (!this.isModified("password")) return;
  
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
});

// 3. Creación y exportación del modelo
const User = mongoose.model("User", userSchema);
export default User;