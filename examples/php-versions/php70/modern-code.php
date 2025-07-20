<?php

/**
 * PHP 7.0 Example Code
 * Features to be modernized:
 * - Scalar type declarations
 * - Return type declarations
 * - Null coalescing operator
 * - Spaceship operator
 * - Anonymous classes
 */

// Modern array syntax (already available in 5.4+)
$users = [
    ['name' => 'John', 'age' => 25],
    ['name' => 'Jane', 'age' => 30],
    ['name' => 'Bob', 'age' => 35]
];

// Variable arguments with type hints
function calculateSum(int ...$numbers): int
{
    return array_sum($numbers);
}

// Class with type hints and return types
class UserManager
{
    const STATUS_ACTIVE = 'active';
    const STATUS_INACTIVE = 'inactive';
    
    private array $users = [];
    
    // Type hints and return types
    public function addUser(string $name, string $email, int $age): bool
    {
        $user = [
            'name' => $name,
            'email' => $email,
            'age' => $age,
            'status' => self::STATUS_ACTIVE
        ];
        
        $this->users[] = $user;
        return true;
    }
    
    public function getUser(int $id): ?array
    {
        return $this->users[$id] ?? null;
    }
    
    public function getUsersByStatus(string $status): array
    {
        return array_filter($this->users, function(array $user) use ($status): bool {
            return $user['status'] === $status;
        });
    }
    
    // Using spaceship operator for sorting
    public function sortUsersByAge(): void
    {
        usort($this->users, function(array $a, array $b): int {
            return $a['age'] <=> $b['age'];
        });
    }
}

// Null coalescing operator
function formatUserInfo(array $user): string
{
    $name = $user['name'] ?? 'Unknown';
    $email = $user['email'] ?? 'No email';
    $age = $user['age'] ?? 'Unknown age';
    
    return "Name: {$name}, Email: {$email}, Age: {$age}";
}

// Anonymous class for configuration
$config = new class {
    public string $host = 'localhost';
    public string $database = 'test';
    public string $username = 'user';
    public string $password = 'pass';
    
    public function getDsn(): string {
        return "mysql:host={$this->host};dbname={$this->database}";
    }
};

// Improved error handling with multiple catch blocks
function connectToDatabase(object $config): ?PDO
{
    try {
        $connection = new PDO(
            $config->getDsn(),
            $config->username,
            $config->password,
            [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
        );
        return $connection;
    } catch (PDOException $e) {
        error_log("Database connection failed: " . $e->getMessage());
        return null;
    } catch (Exception $e) {
        error_log("Unexpected error: " . $e->getMessage());
        return null;
    }
}

// Group use declarations
use Some\Namespace\{ClassA, ClassB, ClassC};

// Usage examples
$manager = new UserManager();
$manager->addUser('Alice', 'alice@example.com', 28);
$manager->addUser('Charlie', 'charlie@example.com', 32);

$users = $manager->getUsersByStatus(UserManager::STATUS_ACTIVE);
$manager->sortUsersByAge();

echo "Sum: " . calculateSum(1, 2, 3, 4, 5) . "\n";

foreach ($users as $user) {
    echo formatUserInfo($user) . "\n";
}
