using System.Globalization;
using System.Windows;
using System.Windows.Controls;
using Entidades;
using Negocio;

namespace Presentacion.Vistas;

public partial class ProductosView : UserControl
{
    private readonly ProductoNegocio _negocio = new();
    private readonly CategoriaNegocio _categorias = new();
    private int _id;
    private bool _papelera;

    public ProductosView()
    {
        InitializeComponent();
        Loaded += (_, _) => { CargarCategorias(); Cargar(); };
    }

    private void CargarCategorias()
    {
        try 
        { 
            cboCategoria.ItemsSource = _categorias.Listar(); 
        }
        catch (Exception ex) 
        { 
            Error(ex); 
        }
    }

    private void Cargar()
    {
        try 
        { 
            var items = _papelera ? _negocio.ListarEliminados(txtBuscar.Text) : _negocio.Buscar(txtBuscar.Text);
            grid.ItemsSource = items;
            lblContador.Text = $"{items.Count} registro{(items.Count == 1 ? "" : "s")}";
        }
        catch (Exception ex) 
        { 
            Error(ex); 
        }
    }

    private void Buscar_Changed(object s, TextChangedEventArgs e) 
    { 
        if (IsLoaded) Cargar(); 
    }

    private void Grid_SelectionChanged(object s, SelectionChangedEventArgs e)
    {
        if (grid.SelectedItem is not Producto p) return;
        _id = p.IdProducto;
        lblTituloForm.Text = $"✏️ Editar Producto #{_id}";
        txtNombre.Text = p.Nombre; 
        txtDescripcion.Text = p.Descripcion; 
        cboCategoria.SelectedValue = p.IdCategoria;
        txtPrecio.Text = p.Precio.ToString(CultureInfo.CurrentCulture); 
        txtStock.Text = p.Stock.ToString();
    }

    private void Guardar_Click(object s, RoutedEventArgs e)
    {
        try
        {
            if (!decimal.TryParse(txtPrecio.Text, NumberStyles.Number, CultureInfo.CurrentCulture, out var precio))
                throw new ArgumentException("El precio no es un número válido.");
            if (!int.TryParse(txtStock.Text, out var stock))
                throw new ArgumentException("El stock debe ser un número entero.");

            _negocio.Guardar(new Producto
            {
                IdProducto = _id, 
                Nombre = txtNombre.Text, 
                Descripcion = txtDescripcion.Text, 
                Precio = precio, 
                Stock = stock,
                IdCategoria = cboCategoria.SelectedValue is int idc ? idc : 0
            });

            MessageBox.Show(_id == 0 ? "Producto registrado exitosamente." : "Producto actualizado exitosamente.",
                "Operación Exitosa", MessageBoxButton.OK, MessageBoxImage.Information);

            Limpiar(); 
            Cargar();
        }
        catch (Exception ex) 
        { 
            Error(ex); 
        }
    }

    private void Eliminar_Click(object s, RoutedEventArgs e)
    {
        if (_id == 0) 
        { 
            MessageBox.Show("Seleccione un producto para eliminar.", "Aviso", MessageBoxButton.OK, MessageBoxImage.Information); 
            return; 
        }

        if (MessageBox.Show($"¿Está seguro de eliminar el producto seleccionado (ID: {_id})?", 
            "Confirmar Eliminación Lógica", MessageBoxButton.YesNo, MessageBoxImage.Question) != MessageBoxResult.Yes) 
            return;

        try 
        { 
            _negocio.Eliminar(_id); 
            MessageBox.Show("El producto fue enviado a la papelera de reciclaje.", "Eliminación Lógica", MessageBoxButton.OK, MessageBoxImage.Information);
            Limpiar(); 
            Cargar(); 
        }
        catch (Exception ex) 
        { 
            Error(ex); 
        }
    }

    private void Papelera_Click(object s, RoutedEventArgs e)
    {
        _papelera = btnPapelera.IsChecked == true;
        btnPapelera.Content = _papelera ? "📦 Ver Activos" : "🗑️ Ver Papelera";
        lblModo.Text = _papelera ? "Modo Papelera (Registros Eliminados)" : "";
        bannerPapelera.Visibility = _papelera ? Visibility.Visible : Visibility.Collapsed;
        colFecha.Visibility = _papelera ? Visibility.Visible : Visibility.Collapsed;

        var normal = _papelera ? Visibility.Collapsed : Visibility.Visible;
        btnGuardar.Visibility = btnNuevo.Visibility = btnEliminar.Visibility = normal;
        btnRestaurar.Visibility = _papelera ? Visibility.Visible : Visibility.Collapsed;

        Limpiar(); 
        Cargar();
    }

    private void Restaurar_Click(object s, RoutedEventArgs e)
    {
        if (_id == 0) 
        { 
            MessageBox.Show("Seleccione un producto eliminado de la tabla.", "Aviso", MessageBoxButton.OK, MessageBoxImage.Information); 
            return; 
        }

        try 
        { 
            _negocio.Restaurar(_id); 
            MessageBox.Show("Producto restaurado al catálogo activo.", "Restauración Exitosa", MessageBoxButton.OK, MessageBoxImage.Information);
            Limpiar(); 
            Cargar(); 
        }
        catch (Exception ex) 
        { 
            Error(ex); 
        }
    }

    private void Nuevo_Click(object s, RoutedEventArgs e) => Limpiar();

    private void Limpiar()
    {
        _id = 0; 
        grid.SelectedItem = null;
        lblTituloForm.Text = "➕ Nuevo Producto";
        txtNombre.Clear(); 
        txtDescripcion.Clear(); 
        cboCategoria.SelectedIndex = -1; 
        txtPrecio.Clear(); 
        txtStock.Clear();
    }

    private static void Error(Exception ex) => MessageBox.Show(ex.Message, "Validación de Negocio", MessageBoxButton.OK, MessageBoxImage.Warning);
}
