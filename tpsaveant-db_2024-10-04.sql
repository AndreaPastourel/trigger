-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Hôte : 127.0.0.1:3306
-- Généré le : ven. 04 oct. 2024 à 18:27
-- Version du serveur : 8.2.0
-- Version de PHP : 8.3.0

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de données : `tpsaveant`
--

DELIMITER $$
--
-- Procédures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `insert_historiqueprix` (IN `p_composantId` INT, IN `p_prix` DOUBLE, IN `p_datemodification` DATETIME)   BEGIN
    -- Insertion dans la table historiqueprix
    INSERT INTO historiqueprix (composantId, prix, dateModification)
    VALUES (p_composantId, p_prix, p_datemodification);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `verifier_et_mettre_a_jour_mdp` (IN `p_client_id` INT, IN `p_nouveau_mdp` VARCHAR(255))   BEGIN
    DECLARE mdp_count INT;

    -- Vérifie si le nouveau mot de passe est l'un des trois derniers
    SELECT COUNT(*) INTO mdp_count
    FROM historique_mdp h1
    LEFT JOIN (
        -- Sous-requête pour sélectionner les 3 derniers mots de passe
        SELECT id FROM historiqueMdp 
        WHERE clientId = p_client_id
        ORDER BY dateModification DESC 
        LIMIT 3
    ) AS subquery ON h1.id = subquery.id
    WHERE h1.clientId = p_client_id
    AND h1.ancien_mdp = p_nouveau_mdp;

    -- Si le mot de passe est trouvé dans les 3 derniers, lever une erreur
    IF mdp_count > 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Le nouveau mot de passe ne peut pas être l’un des trois derniers utilisés.';
    ELSE
        -- Mettre à jour le mot de passe du client dans la table 'client'
        UPDATE client
        SET password = p_nouveau_mdp
        WHERE id = p_client_id;

        -- Ajouter l’ancien mot de passe dans la table historique
        INSERT INTO historiqueMdp (clientId, ancienMdp)
        VALUES (p_client_id, p_nouveau_mdp);

        -- Supprimer l'entrée la plus ancienne si plus de trois mots de passe sont stockés
        DELETE FROM historiqueMdp
        WHERE clientId = p_client_id
        AND id NOT IN (
            SELECT id FROM (
                SELECT id FROM historiqueMdp 
                WHERE clientId = p_client_id
                ORDER BY dateModification DESC 
                LIMIT 3
            ) AS subquery
        );
    END IF;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `achat`
--

CREATE TABLE `achat` (
  `commandeId` int NOT NULL,
  `composantId` int NOT NULL,
  `quantité` int NOT NULL,
  `prixUnitaire` double NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Déchargement des données de la table `achat`
--

INSERT INTO `achat` (`commandeId`, `composantId`, `quantité`, `prixUnitaire`) VALUES
(1, 2, 4, 90.4),
(1, 3, 2, 42.31);

-- --------------------------------------------------------

--
-- Structure de la table `client`
--

CREATE TABLE `client` (
  `id` int NOT NULL,
  `login` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `password` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `nom` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `prenom` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `dateNaissance` date DEFAULT NULL,
  `genre` enum('M','F','non precise') DEFAULT NULL,
  `adressePostal` varchar(254) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `email` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `telephone` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Déchargement des données de la table `client`
--

INSERT INTO `client` (`id`, `login`, `password`, `nom`, `prenom`, `dateNaissance`, `genre`, `adressePostal`, `email`, `telephone`) VALUES
(1, 'jdoe', 'password123', 'Doe', 'John', '1980-05-15', 'M', '123 rue de la République 75001 Paris', 'John.doe@email.com', '0123456789');

--
-- Déclencheurs `client`
--
DELIMITER $$
CREATE TRIGGER `avant_update_mdp` BEFORE UPDATE ON `client` FOR EACH ROW BEGIN
    -- Appeler la procédure de vérification avant mise à jour du mot de passe
    IF NEW.password <> OLD.password THEN
        CALL verifier_et_mettre_a_jour_mdp(OLD.id, NEW.password);
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `genre` BEFORE INSERT ON `client` FOR EACH ROW BEGIN 

IF NEW.genre NOT in ("M","F","non precise") THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Valeur du genre invalide. Seulement M ou F ou non precise sont autorisés.';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `commande`
--

CREATE TABLE `commande` (
  `id` int NOT NULL,
  `dateCommande` date NOT NULL,
  `clientId` int NOT NULL,
  `prixTotal` double NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Déchargement des données de la table `commande`
--

INSERT INTO `commande` (`id`, `dateCommande`, `clientId`, `prixTotal`) VALUES
(1, '2024-10-03', 1, 446.22);

-- --------------------------------------------------------

--
-- Structure de la table `composant`
--

CREATE TABLE `composant` (
  `id` int NOT NULL,
  `nom` varchar(254) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `typeId` int NOT NULL,
  `prix` double NOT NULL,
  `quantiteDisponible` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Déchargement des données de la table `composant`
--

INSERT INTO `composant` (`id`, `nom`, `typeId`, `prix`, `quantiteDisponible`) VALUES
(1, 'Asus TUF GAMING B760-PLUS', 1, 230.2, 10),
(2, 'Kingston ValueRAM DDR5-4800 16Go', 2, 96.99, 20),
(3, 'Samsung SSD 980 M.2', 3, 43.31, 15);

--
-- Déclencheurs `composant`
--
DELIMITER $$
CREATE TRIGGER `historique_prix_composant` AFTER UPDATE ON `composant` FOR EACH ROW BEGIN
       IF NEW.prix <> OLD.prix THEN
        -- Appel de la procédure stockée pour insérer dans historiqueprix
        CALL insert_historiqueprix(OLD.id, NEW.prix, NOW());
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `historiquemdp`
--

CREATE TABLE `historiquemdp` (
  `id` int NOT NULL,
  `clientId` int DEFAULT NULL,
  `ancienMdp` varchar(255) DEFAULT NULL,
  `dateModification` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Structure de la table `historiqueprix`
--

CREATE TABLE `historiqueprix` (
  `id` int NOT NULL,
  `composantId` int NOT NULL,
  `prix` double NOT NULL,
  `dateModification` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Déchargement des données de la table `historiqueprix`
--

INSERT INTO `historiqueprix` (`id`, `composantId`, `prix`, `dateModification`) VALUES
(3, 1, 1, '2024-10-04'),
(4, 1, 215, '2024-10-04'),
(5, 1, 230.2, '2024-10-04'),
(6, 2, 100.2, '2024-10-04'),
(7, 2, 96.3, '2024-10-04'),
(8, 2, 102.3, '2024-10-04'),
(9, 2, 101.99, '2024-10-04'),
(10, 2, 96.99, '2024-10-04'),
(11, 3, 45.31, '2024-10-04'),
(12, 3, 44.31, '2024-10-04'),
(13, 3, 43.31, '2024-10-04');

-- --------------------------------------------------------

--
-- Structure de la table `typecomposant`
--

CREATE TABLE `typecomposant` (
  `id` int NOT NULL,
  `nom` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Déchargement des données de la table `typecomposant`
--

INSERT INTO `typecomposant` (`id`, `nom`) VALUES
(1, 'Carte-mère'),
(2, 'Mémoire'),
(3, 'SSD');

--
-- Index pour les tables déchargées
--

--
-- Index pour la table `achat`
--
ALTER TABLE `achat`
  ADD PRIMARY KEY (`commandeId`,`composantId`),
  ADD KEY `composantId` (`composantId`);

--
-- Index pour la table `client`
--
ALTER TABLE `client`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `commande`
--
ALTER TABLE `commande`
  ADD PRIMARY KEY (`id`),
  ADD KEY `clientId` (`clientId`);

--
-- Index pour la table `composant`
--
ALTER TABLE `composant`
  ADD PRIMARY KEY (`id`),
  ADD KEY `typeId` (`typeId`);

--
-- Index pour la table `historiquemdp`
--
ALTER TABLE `historiquemdp`
  ADD PRIMARY KEY (`id`),
  ADD KEY `clientId` (`clientId`);

--
-- Index pour la table `historiqueprix`
--
ALTER TABLE `historiqueprix`
  ADD PRIMARY KEY (`id`),
  ADD KEY `composantId` (`composantId`);

--
-- Index pour la table `typecomposant`
--
ALTER TABLE `typecomposant`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT pour les tables déchargées
--

--
-- AUTO_INCREMENT pour la table `client`
--
ALTER TABLE `client`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT pour la table `commande`
--
ALTER TABLE `commande`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT pour la table `composant`
--
ALTER TABLE `composant`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT pour la table `historiquemdp`
--
ALTER TABLE `historiquemdp`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `historiqueprix`
--
ALTER TABLE `historiqueprix`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT pour la table `typecomposant`
--
ALTER TABLE `typecomposant`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- Contraintes pour les tables déchargées
--

--
-- Contraintes pour la table `achat`
--
ALTER TABLE `achat`
  ADD CONSTRAINT `achat_ibfk_1` FOREIGN KEY (`commandeId`) REFERENCES `commande` (`id`),
  ADD CONSTRAINT `achat_ibfk_2` FOREIGN KEY (`composantId`) REFERENCES `composant` (`id`);

--
-- Contraintes pour la table `commande`
--
ALTER TABLE `commande`
  ADD CONSTRAINT `commande_ibfk_1` FOREIGN KEY (`clientId`) REFERENCES `client` (`id`);

--
-- Contraintes pour la table `composant`
--
ALTER TABLE `composant`
  ADD CONSTRAINT `composant_ibfk_1` FOREIGN KEY (`typeId`) REFERENCES `typecomposant` (`id`);

--
-- Contraintes pour la table `historiquemdp`
--
ALTER TABLE `historiquemdp`
  ADD CONSTRAINT `historiquemdp_ibfk_1` FOREIGN KEY (`clientId`) REFERENCES `client` (`id`);

--
-- Contraintes pour la table `historiqueprix`
--
ALTER TABLE `historiqueprix`
  ADD CONSTRAINT `historiqueprix_ibfk_1` FOREIGN KEY (`composantId`) REFERENCES `composant` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
