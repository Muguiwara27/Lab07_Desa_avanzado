using Microsoft.Data.SqlClient;

namespace Datos;

public static class Conexion
{
    private static string? _cadena;

    public static string Cadena
    {
        get => _cadena ??= ResolverCadena();
        set => _cadena = value;
    }

    private static string ResolverCadena()
    {
        var env = Environment.GetEnvironmentVariable("LABCRUD_CONN");
        if (!string.IsNullOrWhiteSpace(env)) return env;

        // Candidatos comunes de SQL Server local en entornos de desarrollo académico y empresarial
        string[] candidatos = [
            "Server=.\\SQLEXPRESS;Database=LabCrud;Trusted_Connection=True;TrustServerCertificate=True;Connection Timeout=3;",
            "Server=localhost;Database=LabCrud;Trusted_Connection=True;TrustServerCertificate=True;Connection Timeout=3;",
            "Server=(localdb)\\MSSQLLocalDB;Database=LabCrud;Trusted_Connection=True;TrustServerCertificate=True;Connection Timeout=3;"
        ];

        foreach (var cs in candidatos)
        {
            try
            {
                using var testCn = new SqlConnection(cs);
                testCn.Open();
                return cs;
            }
            catch
            {
                // Intentar con el siguiente candidato
            }
        }

        return "Server=.\\SQLEXPRESS;Database=LabCrud;Trusted_Connection=True;TrustServerCertificate=True;";
    }

    public static SqlConnection Crear() => new(Cadena);

    // Crea un comando de procedimiento almacenado.
    public static SqlCommand Sp(SqlConnection cn, string nombre) =>
        new(nombre, cn) { CommandType = System.Data.CommandType.StoredProcedure };
}
