#!/bin/bash
set -euo pipefail

# Obtener y exportar la fecha actual en formato YYYYMMDD
export date=$(date +%Y%m%d)
echo "Fecha establecida: $date"

# Nombre del submódulo y la carpeta destino
submodule_dir="runbooks"
dest_dir="runbooks-${date}"

# Si el submódulo no existe, agregarlo
if [ ! -d "$submodule_dir" ]; then
    echo "Agregando submódulo..."
    git submodule add --depth=1 --branch master https://github.com/openshift/runbooks.git "$submodule_dir"
fi

# Actualizar el submódulo con la última versión
echo "Actualizando submódulo..."
git submodule update --remote --merge "$submodule_dir"

# Crear un directorio temporal con el nombre basado en la fecha
echo "Creando directorio de trabajo: $dest_dir"
rm -rf "$dest_dir"
cp -r "$submodule_dir" "$dest_dir"
cd "$dest_dir"

# Configurar sparse-checkout para solo traer la carpeta "alerts"
git sparse-checkout init --cone
git sparse-checkout set alerts
git checkout

# Eliminar archivos que no sean Markdown o sean README.md/example.md
find . -type f \( ! -name '*.md' -o -name 'README.md' -o -name 'example.md' \) -exec rm -f {} +

# Eliminar directorios vacíos y los llamados 'deprecated'
find . -depth -type d \( -empty -o -name 'deprecated' \) -exec rm -rf {} +

# Crear el directorio para los archivos combinados
mkdir -p alerts-merged
cd alerts

# Para cada subdirectorio, generar un archivo Markdown combinado
for dir in */; do
    if [ -d "$dir" ]; then
        dir_name="${dir%/}"
        merged_file="${dir_name}-merged.md"
        echo "Generando el archivo combinado: ${merged_file}"
        > "$merged_file"
        
        # Unir todos los archivos markdown del directorio con encabezados y separadores
        find "$dir" -type f -name '*.md' | sort | while read -r mdfile; do
            echo "Original Filename:  $(basename "$mdfile")" >> "$merged_file"
            echo "" >> "$merged_file"
            cat "$mdfile" >> "$merged_file"
            echo -e "\n\n" >> "$merged_file"
            echo "------------------------------" >> "$merged_file"
            echo -e "\n" >> "$merged_file"
        done
    fi
done

# Mover archivos combinados al directorio de salida
find . -maxdepth 1 -type f -name '*-merged.md' -exec mv -t ../alerts-merged/ {} +

# Copiar archivos Markdown restantes de nivel superior al directorio de salida
find . -maxdepth 1 -type f -name '*.md' -exec cp -t ../alerts-merged/ {} +

echo "Proceso completado. Archivos generados en '$dest_dir/alerts-merged'"