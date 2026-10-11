-- ============================================================================
-- BASE DE DATOS: LabCrud
-- Arquitectura en Capas: Entidades, Datos, Negocio, Presentacion (WPF)
-- Script Completo: Tablas, Relaciones, Índices, Procedimientos Almacenados y Datos
-- ============================================================================

IF DB_ID(N'LabCrud') IS NULL
BEGIN
    CREATE DATABASE LabCrud;
END
GO

USE LabCrud;
GO

-- 1. TABLA: Categoria
IF OBJECT_ID(N'dbo.Categoria', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Categoria (
        IdCategoria INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Categoria PRIMARY KEY,
        Nombre      NVARCHAR(100) NOT NULL CONSTRAINT UQ_Categoria_Nombre UNIQUE
    );
END
GO

-- 2. TABLA: Producto
IF OBJECT_ID(N'dbo.Producto', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Producto (
        IdProducto       INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Producto PRIMARY KEY,
        Nombre           NVARCHAR(100) NOT NULL,
        Descripcion      NVARCHAR(250) NULL,
        Precio           DECIMAL(10,2) NOT NULL CONSTRAINT CK_Producto_Precio CHECK (Precio >= 0),
        Stock            INT NOT NULL CONSTRAINT CK_Producto_Stock CHECK (Stock >= 0),
        Estado           BIT NOT NULL CONSTRAINT DF_Producto_Estado DEFAULT (1), -- 1 = Activo, 0 = Eliminado
        IdCategoria      INT NOT NULL CONSTRAINT FK_Producto_Categoria FOREIGN KEY REFERENCES dbo.Categoria(IdCategoria),
        FechaEliminacion DATETIME NULL,
        FechaCreacion    DATETIME NOT NULL CONSTRAINT DF_Producto_FechaCreacion DEFAULT (GETDATE())
    );
END
GO

-- Índices para optimizar búsquedas y listados
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Producto_Estado' AND object_id = OBJECT_ID(N'dbo.Producto'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Producto_Estado 
    ON dbo.Producto(Estado) 
    INCLUDE (Nombre, Precio, Stock, IdCategoria, FechaEliminacion);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Producto_IdCategoria' AND object_id = OBJECT_ID(N'dbo.Producto'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Producto_IdCategoria 
    ON dbo.Producto(IdCategoria);
END
GO

-- ============================================================================
-- PROCEDIMIENTOS ALMACENADOS
-- ============================================================================

-- Listar categorías
CREATE OR ALTER PROCEDURE dbo.sp_Categoria_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT IdCategoria, Nombre
    FROM dbo.Categoria
    ORDER BY Nombre ASC;
END;
GO

-- Listar productos activos
CREATE OR ALTER PROCEDURE dbo.sp_Producto_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        p.IdProducto,
        p.Nombre,
        p.Descripcion,
        p.Precio,
        p.Stock,
        p.Estado,
        p.IdCategoria,
        c.Nombre AS Categoria,
        p.FechaEliminacion
    FROM dbo.Producto p
    INNER JOIN dbo.Categoria c ON p.IdCategoria = c.IdCategoria
    WHERE p.Estado = 1
    ORDER BY p.Nombre ASC;
END;
GO

-- Buscar productos activos (por nombre, descripción o categoría)
CREATE OR ALTER PROCEDURE dbo.sp_Producto_Buscar
    @Texto NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        p.IdProducto,
        p.Nombre,
        p.Descripcion,
        p.Precio,
        p.Stock,
        p.Estado,
        p.IdCategoria,
        c.Nombre AS Categoria,
        p.FechaEliminacion
    FROM dbo.Producto p
    INNER JOIN dbo.Categoria c ON p.IdCategoria = c.IdCategoria
    WHERE p.Estado = 1
      AND (
          p.Nombre LIKE N'%' + @Texto + N'%'
          OR ISNULL(p.Descripcion, N'') LIKE N'%' + @Texto + N'%'
          OR c.Nombre LIKE N'%' + @Texto + N'%'
      )
    ORDER BY p.Nombre ASC;
END;
GO

-- Listar productos eliminados (Papelera)
CREATE OR ALTER PROCEDURE dbo.sp_Producto_ListarEliminados
    @Texto NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        p.IdProducto,
        p.Nombre,
        p.Descripcion,
        p.Precio,
        p.Stock,
        p.Estado,
        p.IdCategoria,
        c.Nombre AS Categoria,
        p.FechaEliminacion
    FROM dbo.Producto p
    INNER JOIN dbo.Categoria c ON p.IdCategoria = c.IdCategoria
    WHERE p.Estado = 0
      AND (
          @Texto IS NULL 
          OR @Texto = N''
          OR p.Nombre LIKE N'%' + @Texto + N'%'
          OR ISNULL(p.Descripcion, N'') LIKE N'%' + @Texto + N'%'
          OR c.Nombre LIKE N'%' + @Texto + N'%'
      )
    ORDER BY p.FechaEliminacion DESC;
END;
GO

-- Insertar producto
CREATE OR ALTER PROCEDURE dbo.sp_Producto_Insertar
    @Nombre      NVARCHAR(100),
    @Descripcion NVARCHAR(250) = NULL,
    @Precio      DECIMAL(10,2),
    @Stock       INT,
    @IdCategoria INT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.Producto (Nombre, Descripcion, Precio, Stock, IdCategoria, Estado, FechaEliminacion)
    VALUES (@Nombre, @Descripcion, @Precio, @Stock, @IdCategoria, 1, NULL);

    SELECT CAST(SCOPE_IDENTITY() AS INT);
END;
GO

-- Actualizar producto
CREATE OR ALTER PROCEDURE dbo.sp_Producto_Actualizar
    @IdProducto  INT,
    @Nombre      NVARCHAR(100),
    @Descripcion NVARCHAR(250) = NULL,
    @Precio      DECIMAL(10,2),
    @Stock       INT,
    @IdCategoria INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.Producto
    SET Nombre = @Nombre,
        Descripcion = @Descripcion,
        Precio = @Precio,
        Stock = @Stock,
        IdCategoria = @IdCategoria
    WHERE IdProducto = @IdProducto AND Estado = 1;

    SELECT @@ROWCOUNT;
END;
GO

-- Eliminación lógica de producto
CREATE OR ALTER PROCEDURE dbo.sp_Producto_Eliminar
    @IdProducto INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.Producto
    SET Estado = 0,
        FechaEliminacion = GETDATE()
    WHERE IdProducto = @IdProducto AND Estado = 1;

    SELECT @@ROWCOUNT;
END;
GO

-- Restaurar producto eliminado
CREATE OR ALTER PROCEDURE dbo.sp_Producto_Restaurar
    @IdProducto INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.Producto
    SET Estado = 1,
        FechaEliminacion = NULL
    WHERE IdProducto = @IdProducto AND Estado = 0;

    SELECT @@ROWCOUNT;
END;
GO

-- Resumen agrupado por categoría (GROUP BY)
CREATE OR ALTER PROCEDURE dbo.sp_Producto_ResumenPorCategoria
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        c.Nombre AS Categoria,
        COUNT(p.IdProducto) AS CantidadProductos,
        ISNULL(SUM(p.Stock), 0) AS StockTotal,
        ISNULL(SUM(p.Precio * p.Stock), 0) AS ValorInventario
    FROM dbo.Categoria c
    LEFT JOIN dbo.Producto p ON c.IdCategoria = p.IdCategoria AND p.Estado = 1
    GROUP BY c.IdCategoria, c.Nombre
    ORDER BY c.Nombre ASC;
END;
GO

-- ============================================================================
-- DATOS INICIALES (SEMILLA)
-- ============================================================================

-- Categorías
IF NOT EXISTS (SELECT 1 FROM dbo.Categoria WHERE Nombre = N'Cómputo')
    INSERT INTO dbo.Categoria (Nombre) VALUES (N'Cómputo');

IF NOT EXISTS (SELECT 1 FROM dbo.Categoria WHERE Nombre = N'Periféricos')
    INSERT INTO dbo.Categoria (Nombre) VALUES (N'Periféricos');

IF NOT EXISTS (SELECT 1 FROM dbo.Categoria WHERE Nombre = N'Audio y Video')
    INSERT INTO dbo.Categoria (Nombre) VALUES (N'Audio y Video');

IF NOT EXISTS (SELECT 1 FROM dbo.Categoria WHERE Nombre = N'Almacenamiento')
    INSERT INTO dbo.Categoria (Nombre) VALUES (N'Almacenamiento');

IF NOT EXISTS (SELECT 1 FROM dbo.Categoria WHERE Nombre = N'Redes y Comunicaciones')
    INSERT INTO dbo.Categoria (Nombre) VALUES (N'Redes y Comunicaciones');

-- Productos de demostración iniciales
IF NOT EXISTS (SELECT 1 FROM dbo.Producto)
BEGIN
    DECLARE @catComputo INT = (SELECT TOP 1 IdCategoria FROM dbo.Categoria WHERE Nombre = N'Cómputo');
    DECLARE @catPerifericos INT = (SELECT TOP 1 IdCategoria FROM dbo.Categoria WHERE Nombre = N'Periféricos');
    DECLARE @catAudio INT = (SELECT TOP 1 IdCategoria FROM dbo.Categoria WHERE Nombre = N'Audio y Video');
    DECLARE @catAlm INT = (SELECT TOP 1 IdCategoria FROM dbo.Categoria WHERE Nombre = N'Almacenamiento');
    DECLARE @catRedes INT = (SELECT TOP 1 IdCategoria FROM dbo.Categoria WHERE Nombre = N'Redes y Comunicaciones');

    INSERT INTO dbo.Producto (Nombre, Descripcion, Precio, Stock, Estado, IdCategoria, FechaEliminacion)
    VALUES 
    (N'Laptop Lenovo ThinkPad E14', N'Intel Core i7 13va Gen, 16GB RAM, 512GB SSD NVMe', 3899.00, 12, 1, @catComputo, NULL),
    (N'Laptop Asus Vivobook Pro', N'AMD Ryzen 7, 16GB RAM, 1TB SSD, RTX 3050', 4250.00, 8, 1, @catComputo, NULL),
    (N'Monitor LG UltraWide 29"', N'IPS 75Hz Full HD sRGB 99% HDMI FreeSync', 849.90, 15, 1, @catPerifericos, NULL),
    (N'Teclado Mecánico Logitech G Pro', N'Switches GX Blue RGB Retroiluminado USB', 419.00, 25, 1, @catPerifericos, NULL),
    (N'Mouse Inalámbrico MX Master 3S', N'Sensor 8000 DPI, Quiet Clicks, Bluetooth', 379.50, 18, 1, @catPerifericos, NULL),
    (N'Auriculares Sony WH-1000XM5', N'Cancelación de Ruido Activa ANC, Bluetooth 5.2', 1299.00, 10, 1, @catAudio, NULL),
    (N'Disco Sólido SSD Kingston NV2 1TB', N'PCIe 4.0 NVMe M.2 3500MB/s lectura', 249.00, 30, 1, @catAlm, NULL),
    (N'Router Wi-Fi 6 TP-Link Archer AX55', N'Dual Band AX3000 Gigabit con OneMesh', 320.00, 14, 1, @catRedes, NULL),
    (N'Cámara Web Logitech C920 Pro', N'Full HD 1080p con micrófonos duales estéreo', 289.00, 0, 1, @catAudio, NULL),
    (N'Laptop Antigua HP 15 (Baja)', N'Equipo retirado de demostración por inventario', 1200.00, 0, 0, @catComputo, DATEADD(DAY, -5, GETDATE()));
END
GO
