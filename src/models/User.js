const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

// 1. Definición del esquema
const userSchema = new mongoose.Schema({
  nombres: { type: String, required: true },
  apellidos: { type: String, required: true },
  documentoIdentidad: { type: String, required: true, unique: true },
  correo: { type: String, required: true, unique: true },
  celular: { type: String, required: true },
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
userSchema.pre("save", async function (next) {
  if (!this.isModified("password")) return next();
  
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
});

// 3. Creación y exportación del modelo al final
module.exports = mongoose.model("User", userSchema);