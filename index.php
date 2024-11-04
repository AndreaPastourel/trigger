<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Graphique d'évolution du prix</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <link rel="stylesheet" href="styles.css"> <!-- Lien vers le fichier CSS -->
</head>
<body>

<?php 
    require_once 'dbConnect.php'; // Connexion à la base de données

    // Récupération des composants et de leurs noms
    $stmt = $pdo->prepare('SELECT DISTINCT composant.id, composant.nom FROM composant JOIN historiqueprix ON composant.id = historiqueprix.composantId');
    $stmt->execute();
    $composants = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Récupération des données du composant sélectionné (si un composant est sélectionné)
    $composant_id = isset($_GET['composant']) ? $_GET['composant'] : null;
    $labels = [];
    $values = [];

    if ($composant_id) {
        // Requête pour récupérer les données de prix pour un composant spécifique
        $stmt = $pdo->prepare('SELECT dateModification, prix FROM historiqueprix WHERE composantId = ? ORDER BY dateModification');
        $stmt->execute([$composant_id]);
        $data = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // Conversion des données pour le graphique Chart.js
        $labels = array_column($data, 'dateModification');
        $values = array_column($data, 'prix');
    }
?>

<h1>Évolution du prix</h1>

<!-- Formulaire pour sélectionner un composant -->
<form method="GET">
    <select name="composant">
        <option value="">Sélectionnez un composant</option>
        <?php foreach ($composants as $composant) : ?>
            <option value="<?= $composant['id'] ?>" <?= $composant['id'] == $composant_id ? 'selected' : '' ?>>
                <?= $composant['nom'] ?> <!-- Affichage du nom du composant -->
            </option>
        <?php endforeach; ?>
    </select>
    <input type="submit" value="Afficher">
</form>

<!-- Zone pour le graphique -->
<div class="chart-container">
    <canvas id="myChart"></canvas>
</div>

<script>
    var ctx = document.getElementById('myChart').getContext('2d');
    var chart = new Chart(ctx, {
        type: 'line',   
        data: {
            labels: <?php echo json_encode($labels); ?>,
            datasets: [{
                label: 'Évolution du prix',
                data: <?php echo json_encode($values); ?>,
                borderColor: 'rgba(75,192,192,1)',
                fill: false
            }]
        },
        options: {
            scales: {
                xAxes: [{
                    type: 'time',
                    time: {
                        unit: 'month' // Unité de temps sur l'axe X
                    }
                }],
                yAxes: [{
                    ticks: {
                        beginAtZero: true // Le prix commence à 0
                    }
                }]
            }
        }
    });
</script>

</body>
</html>