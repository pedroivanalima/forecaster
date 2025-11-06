location1 = Location.find_or_create_by({
    latitude: -16.82,
    longitude: -49.24,
    name: "Ap. de Goiânia",
    display_name: "Aparecida de Goiânia, Região Geográfica Imediata de Goiânia, Região Geográfica Intermediária de Goiânia, Goiás, Região Centro-Oeste, Brasil",
    search: ["Aparecida de Goiânia", "Key123"]
})

location2 = Location.find_or_create_by({
    latitude: -16.67,
    longitude: -49.25,
    name: "Goiânia",
    display_name: "Goiânia, Região Geográfica Imediata de Goiânia, Região Geográfica Intermediária de Goiânia, Goiás, Região Centro-Oeste, Brasil",
    search: ["Goiânia", "Key123"]
})