import bcrypt from 'bcryptjs';
import User from '../models/User.js';

export const crearAdminSemilla = async () => {
  try {
    const adminExiste = await User.findOne({ 
      $or: [{ correo: 'spavehicular01@gmail.com' }, { Correo_Electronico: 'spavehicular01@gmail.com' }] 
    });

    if (!adminExiste) {
      const passwordEncriptada = await bcrypt.hash('spa_veh_01', 10);
      
      const nuevoAdmin = new User({
        Nombre: 'Administrador',
        nombres: 'Administrador',
        Apellido: 'Cars Wash',
        apellidos: 'Cars Wash',
        Correo_Electronico: 'spavehicular01@gmail.com',
        correo: 'spavehicular01@gmail.com',
        passwords: passwordEncriptada,
        password: passwordEncriptada,
        telefono: '3202819751',
        celular: '3202819751',
        rol: 'admin',
        isVerified: true
      });

      await nuevoAdmin.save();
      console.log('👑 Usuario Administrador creado exitosamente.');
    } else {
      console.log('ℹ️ El Administrador ya existe en la base de datos.');
    }
  } catch (error) {
    console.error('🔥 Error al crear el Administrador semilla:', error);
  }
};