using System.Globalization;
using System.Windows;
using System.Windows.Controls;
using Negocio;

namespace Presentacion.Vistas;

public partial class ResumenView : UserControl
{
    private readonly ProductoNegocio _negocio = new();

    public ResumenView()
    {
        InitializeComponent();
        IsVisibleChanged += (_, e) => { if ((bool)e.NewValue) Cargar(); };
    }

    private void Cargar()
    {
        try 
        { 
            var lista = _negocio.ResumenPorCategoria(); 
            grid.ItemsSource = lista; 

            // Actualizar tarjetas de métricas (KPIs)
            txtTotalCategorias.Text = lista.Count.ToString();
            txtTotalProductos.Text = lista.Sum(x => x.CantidadProductos).ToString("N0");
            txtStockTotal.Text = lista.Sum(x => x.StockTotal).ToString("N0");
            txtValorTotal.Text = string.Format(CultureInfo.CurrentCulture, "S/ {0:N2}", lista.Sum(x => x.ValorInventario));
        }
        catch (Exception ex) 
        { 
            MessageBox.Show(ex.Message, "Error al Cargar Resumen", MessageBoxButton.OK, MessageBoxImage.Warning); 
        }
    }

    private void Actualizar_Click(object s, RoutedEventArgs e) => Cargar();
}
