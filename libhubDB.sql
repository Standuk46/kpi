-- Створюємо базу даних
CREATE DATABASE IF NOT EXISTS libhub;
USE libhub;

-- Встановлюємо кодування
SET NAMES utf8mb4;
SET time_zone = '+00:00';
SET foreign_key_checks = 0;

-- 1. КОРИСТУВАЧІ ТА РОЛІ (Майже без змін)
DROP TABLE IF EXISTS Roles;
CREATE TABLE Roles (
  role_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
  role_name VARCHAR(50) NOT NULL,
  UNIQUE KEY role_name_UNIQUE (role_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS Users;
CREATE TABLE Users (
  user_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) DEFAULT NULL,
  email VARCHAR(255) NOT NULL,
  phone_number VARCHAR(20) DEFAULT NULL,
  password_hash VARCHAR(255) NOT NULL,
  reader_ticket_number VARCHAR(50) DEFAULT NULL COMMENT 'Номер читацького квитка',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY email_UNIQUE (email),
  UNIQUE KEY ticket_UNIQUE (reader_ticket_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS UserRoles;
CREATE TABLE UserRoles (
  user_id INT NOT NULL,
  role_id INT NOT NULL,
  PRIMARY KEY (user_id, role_id),
  CONSTRAINT fk_UserRoles_Users FOREIGN KEY (user_id) REFERENCES Users (user_id) ON DELETE CASCADE,
  CONSTRAINT fk_UserRoles_Roles FOREIGN KEY (role_id) REFERENCES Roles (role_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. КНИГИ ТА КАТАЛОГ
-- Категорії перейменовано на Жанри (Genres), логіка та ж
DROP TABLE IF EXISTS Genres;
CREATE TABLE Genres (
  genre_id INT NOT NULL AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL,
  description TEXT DEFAULT NULL,
  parent_genre_id INT DEFAULT NULL, -- Для піджанрів (Фантастика -> Кіберпанк)
  PRIMARY KEY (genre_id),
  UNIQUE KEY name_UNIQUE (name),
  CONSTRAINT fk_Genres_Parent FOREIGN KEY (parent_genre_id) REFERENCES Genres (genre_id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Автори (Нова таблиця)
DROP TABLE IF EXISTS Authors;
CREATE TABLE Authors (
  author_id INT NOT NULL AUTO_INCREMENT,
  full_name VARCHAR(255) NOT NULL,
  bio TEXT DEFAULT NULL,
  PRIMARY KEY (author_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Книги (Загальна інформація про видання)
DROP TABLE IF EXISTS Books;
CREATE TABLE Books (
  book_id INT NOT NULL AUTO_INCREMENT,
  genre_id INT DEFAULT NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT DEFAULT NULL,
  isbn VARCHAR(20) DEFAULT NULL COMMENT 'Унікальний код книги',
  publication_year INT DEFAULT NULL,
  publisher VARCHAR(100) DEFAULT NULL,
  cover_image_url VARCHAR(255) DEFAULT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (book_id),
  UNIQUE KEY isbn_UNIQUE (isbn),
  CONSTRAINT fk_Books_Genres FOREIGN KEY (genre_id) REFERENCES Genres (genre_id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Зв'язок Книги <-> Автори (Багато до багатьох)
DROP TABLE IF EXISTS BookAuthors;
CREATE TABLE BookAuthors (
  book_id INT NOT NULL,
  author_id INT NOT NULL,
  PRIMARY KEY (book_id, author_id),
  CONSTRAINT fk_BA_Books FOREIGN KEY (book_id) REFERENCES Books (book_id) ON DELETE CASCADE,
  CONSTRAINT fk_BA_Authors FOREIGN KEY (author_id) REFERENCES Authors (author_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. ФІЗИЧНІ ЕКЗЕМПЛЯРИ ТА ВИДАЧА
-- Конкретні фізичні копії книг на полицях
DROP TABLE IF EXISTS BookCopies;
CREATE TABLE BookCopies (
  copy_id INT NOT NULL AUTO_INCREMENT,
  book_id INT NOT NULL,
  inventory_number VARCHAR(50) NOT NULL COMMENT 'Штрихкод на книзі',
  status ENUM('Available', 'OnLoan', 'Reserved', 'Lost', 'Damaged') NOT NULL DEFAULT 'Available',
  location_code VARCHAR(50) DEFAULT NULL COMMENT 'Де лежить: Зал 1, Полиця 5',
  PRIMARY KEY (copy_id),
  UNIQUE KEY inv_num_UNIQUE (inventory_number),
  CONSTRAINT fk_Copies_Books FOREIGN KEY (book_id) REFERENCES Books (book_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Видачі книг (Замість Orders)
DROP TABLE IF EXISTS Loans;
CREATE TABLE Loans (
  loan_id INT NOT NULL AUTO_INCREMENT,
  user_id INT NOT NULL,
  copy_id INT NOT NULL,
  loan_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  due_date DATETIME NOT NULL COMMENT 'Дата, коли треба повернути',
  return_date DATETIME DEFAULT NULL COMMENT 'Фактична дата повернення',
  status ENUM('Active', 'Returned', 'Overdue') NOT NULL DEFAULT 'Active',
  PRIMARY KEY (loan_id),
  CONSTRAINT fk_Loans_Users FOREIGN KEY (user_id) REFERENCES Users (user_id) ON DELETE RESTRICT,
  CONSTRAINT fk_Loans_Copies FOREIGN KEY (copy_id) REFERENCES BookCopies (copy_id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Бронювання (Якщо всі копії зайняті або людина хоче відкласти книгу)
DROP TABLE IF EXISTS Reservations;
CREATE TABLE Reservations (
  reservation_id INT NOT NULL AUTO_INCREMENT,
  user_id INT NOT NULL,
  book_id INT NOT NULL COMMENT 'Бронюємо назву, а не конкретну копію',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  status ENUM('Pending', 'Ready', 'Completed', 'Cancelled') NOT NULL DEFAULT 'Pending',
  PRIMARY KEY (reservation_id),
  CONSTRAINT fk_Res_Users FOREIGN KEY (user_id) REFERENCES Users (user_id) ON DELETE CASCADE,
  CONSTRAINT fk_Res_Books FOREIGN KEY (book_id) REFERENCES Books (book_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- 4. ДОДАТКОВІ ТАБЛИЦІ
-- Відгуки (ідентично до магазину)
DROP TABLE IF EXISTS Reviews;
CREATE TABLE Reviews (
  review_id INT NOT NULL AUTO_INCREMENT,
  user_id INT DEFAULT NULL,
  book_id INT NOT NULL,
  rating INT NOT NULL,
  review_text TEXT DEFAULT NULL,
  review_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (review_id),
  CONSTRAINT chk_rating CHECK (rating >= 1 AND rating <= 5),
  CONSTRAINT fk_Reviews_Users FOREIGN KEY (user_id) REFERENCES Users (user_id) ON DELETE SET NULL,
  CONSTRAINT fk_Reviews_Books FOREIGN KEY (book_id) REFERENCES Books (book_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Список бажаного (ідентично)
DROP TABLE IF EXISTS Wishlists;
CREATE TABLE Wishlists (
  user_id INT NOT NULL,
  book_id INT NOT NULL,
  added_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, book_id),
  CONSTRAINT fk_Wish_Users FOREIGN KEY (user_id) REFERENCES Users (user_id) ON DELETE CASCADE,
  CONSTRAINT fk_Wish_Books FOREIGN KEY (book_id) REFERENCES Books (book_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET foreign_key_checks = 1;

-- 5. ТЕСТОВІ ДАНІ (LibHub)
INSERT INTO Roles (role_name) VALUES ('Admin'), ('Reader');

INSERT INTO Genres (genre_id, name, description) VALUES
(1, 'Художня література', 'Романи, повісті, оповідання'),
(2, 'Наука та освіта', 'Підручники, наукові праці'),
(3, 'Фантастика', 'Sci-Fi та Фентезі'),
(4, 'Психологія', 'Книги з саморозвитку'),
(5, 'Дитяча література', 'Казки та вірші для дітей');

-- Додамо авторів
INSERT INTO Authors (full_name) VALUES 
('Джордж Орвелл'), ('Тарас Шевченко'), ('Стівен Кінг');

-- Додамо книги (Каталог)
INSERT INTO Books (book_id, genre_id, title, isbn, publication_year, publisher) VALUES
(1, 1, '1984', '9780451524935', 1949, 'Secker & Warburg'),
(2, 1, 'Кобзар', '9789660378877', 1840, 'Дніпро'),
(3, 3, 'Сяйво', '9780307743657', 1977, 'Doubleday');

-- Зв’яжемо книги з авторами
INSERT INTO BookAuthors (book_id, author_id) VALUES 
(1, 1), (2, 2), (3, 3);

-- Додамо фізичні копії (Інвентар)
INSERT INTO BookCopies (book_id, inventory_number, status, location_code) VALUES
(1, 'INV-1001', 'Available', 'A1-2'), -- 1984 (Копія 1)
(1, 'INV-1002', 'OnLoan', 'A1-2'),    -- 1984 (Копія 2, видана)
(2, 'INV-2001', 'Available', 'B3-5'), -- Кобзар
(3, 'INV-3001', 'Damaged', 'Storage'); -- Сяйво (пошкоджена)