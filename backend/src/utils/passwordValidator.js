// Guardar en: backend/utils/passwordValidator.js
// Devuelve null si la contraseña es válida, o un mensaje de error en español.
export const MIN_PASSWORD_LENGTH = 8;

export const validarPassword = (password) => {
  if (typeof password !== 'string' || password.length === 0) {
    return 'La contraseña es obligatoria.';
  }
  if (password.length < MIN_PASSWORD_LENGTH) {
    return `La contraseña debe tener mínimo ${MIN_PASSWORD_LENGTH} caracteres.`;
  }
  if (!/[A-Z]/.test(password)) {
    return 'La contraseña debe incluir al menos una letra mayúscula.';
  }
  if (!/[0-9]/.test(password)) {
    return 'La contraseña debe incluir al menos un número.';
  }
  if (!/[^A-Za-z0-9\s]/.test(password)) {
    return 'La contraseña debe incluir al menos un caracter especial.';
  }
  return null;
};