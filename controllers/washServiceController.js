import WashService from "../models/wash_service.js";
import { borrarImagenCloudinary } from "../utils/cloudinary.js";

export const crearServicio = async (req, res) => {
    try {
        const { Nombre, Descripcion, Precio } = req.body;

        if (!Nombre || !Descripcion || !Precio) {
            return res.status(400).json({ message: "Nombre, descripción y precio son obligatorios" });
        }
        if (!req.file) {
            return res.status(400).json({ message: "Debes subir una imagen del servicio" });
        }

        const nuevoServicio = new WashService({
            serviceId: `SERV-${Date.now()}`,
            Nombre,
            Descripcion,
            Precio: parseInt(Precio, 10),
            Image: req.file.path, // Almacena la URL pública de Cloudinary
        });

        await nuevoServicio.save();
        res.status(201).json({ message: "Servicio guardado con éxito", servicio: nuevoServicio });
    } catch (error) {
        console.error("Error al guardar el servicio", error);
        res.status(400).json({ message: "Error al ingresar el servicio", error: error.message });
    }
};

export const obtenerServicios = async (req, res) => {
    try {
        const servicios = await WashService.find();
        res.status(200).json(servicios);
    } catch (error) {
        res.status(500).json({ message: "Error al obtener los servicios" });
    }
};

export const actualizarServicio = async (req, res) => {
    try {
        const { id } = req.params;
        const servicio = await WashService.findById(id);
        if (!servicio) {
            return res.status(404).json({ message: "Servicio no encontrado" });
        }

        const { Nombre, Descripcion, Precio } = req.body;
        servicio.Nombre = Nombre ?? servicio.Nombre;
        servicio.Descripcion = Descripcion ?? servicio.Descripcion;
        servicio.Precio = Precio ? parseInt(Precio, 10) : servicio.Precio;

        if (req.file) {
            await borrarImagenCloudinary(servicio.Image);
            servicio.Image = req.file.path;
        }

        await servicio.save();
        res.json({ message: "Servicio actualizado", servicioActualizado: servicio });
    } catch (error) {
        console.error("Error al actualizar el servicio", error);
        res.status(400).json({ message: "Error al actualizar servicio", error: error.message });
    }
};

export const eliminarServicio = async (req, res) => {
    try {
        const { id } = req.params;
        const servicioEliminado = await WashService.findByIdAndDelete(id);
        if (!servicioEliminado) {
            return res.status(404).json({ message: "Servicio no encontrado" });
        }

        await borrarImagenCloudinary(servicioEliminado.Image);
        res.json({ message: "Servicio eliminado correctamente" });
    } catch (error) {
        res.status(400).json({ message: "Error al eliminar servicio", error: error.message });
    }
};