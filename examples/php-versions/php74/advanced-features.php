<?php

/**
 * PHP 7.4 Example Code
 * Features to be modernized:
 * - Typed properties
 * - Arrow functions
 * - Null coalescing assignment operator
 * - Spread operator in array expressions
 * - Preloading
 */

declare(strict_types=1);

// Class with typed properties
class UserManager
{
    private const STATUS_ACTIVE = 'active';
    private const STATUS_INACTIVE = 'inactive';
    
    private array $users = [];
    private ?PDO $connection = null;
    private string $cacheKey;
    private int $maxUsers = 1000;
    
    public function __construct(string $cacheKey = 'users')
    {
        $this->cacheKey = $cacheKey;
    }
    
    public function addUser(string $name, string $email, int $age): bool
    {
        if (count($this->users) >= $this->maxUsers) {
            throw new InvalidArgumentException('Maximum users limit reached');
        }
        
        $user = [
            'id' => uniqid(),
            'name' => $name,
            'email' => $email,
            'age' => $age,
            'status' => self::STATUS_ACTIVE,
            'created_at' => new DateTimeImmutable()
        ];
        
        $this->users[] = $user;
        return true;
    }
    
    public function getUser(string $id): ?array
    {
        return array_filter($this->users, fn(array $user): bool => $user['id'] === $id)[0] ?? null;
    }
    
    // Arrow functions for filtering
    public function getActiveUsers(): array
    {
        return array_filter($this->users, fn(array $user): bool => $user['status'] === self::STATUS_ACTIVE);
    }
    
    public function getUsersByAgeRange(int $minAge, int $maxAge): array
    {
        return array_filter(
            $this->users,
            fn(array $user): bool => $user['age'] >= $minAge && $user['age'] <= $maxAge
        );
    }
    
    // Null coalescing assignment operator
    public function getConnection(): PDO
    {
        $this->connection ??= $this->createConnection();
        return $this->connection;
    }
    
    private function createConnection(): PDO
    {
        return new PDO('sqlite::memory:');
    }
    
    // Spread operator in arrays
    public function mergeUsers(array ...$userLists): array
    {
        return [...$this->users, ...$userLists[0], ...$userLists[1] ?? []];
    }
}

// Numeric literal separator (PHP 7.4)
class Config
{
    private const MAX_FILE_SIZE = 10_000_000; // 10MB
    private const CACHE_TTL = 3_600; // 1 hour
    
    private array $settings = [];
    
    public function setSetting(string $key, mixed $value): void
    {
        $this->settings[$key] = $value;
    }
    
    public function getSetting(string $key): mixed
    {
        return $this->settings[$key] ?? null;
    }
}

// Arrow functions for data transformation
function processUsers(array $users): array
{
    return array_map(
        fn(array $user): array => [
            'id' => $user['id'],
            'display_name' => ucfirst($user['name']),
            'email_domain' => explode('@', $user['email'])[1] ?? 'unknown',
            'age_group' => $user['age'] < 30 ? 'young' : 'adult'
        ],
        $users
    );
}

// Complex arrow function with multiple operations
function calculateStatistics(array $users): array
{
    $ages = array_map(fn(array $user): int => $user['age'], $users);
    
    return [
        'total' => count($users),
        'average_age' => array_sum($ages) / count($ages),
        'min_age' => min($ages),
        'max_age' => max($ages),
        'young_users' => count(array_filter($users, fn(array $user): bool => $user['age'] < 30))
    ];
}

// Foreign Function Interface (FFI) example
if (extension_loaded('ffi')) {
    $ffi = FFI::cdef("
        int printf(const char *format, ...);
    ", "libc.so.6");
}

// Usage examples
$manager = new UserManager('user_cache_v2');
$manager->addUser('Alice', 'alice@example.com', 28);
$manager->addUser('Bob', 'bob@company.org', 35);
$manager->addUser('Charlie', 'charlie@startup.io', 24);

$activeUsers = $manager->getActiveUsers();
$youngUsers = $manager->getUsersByAgeRange(20, 30);

$processedUsers = processUsers($activeUsers);
$stats = calculateStatistics($activeUsers);

echo "Statistics: " . json_encode($stats, JSON_PRETTY_PRINT) . "\n";

// Weak references (PHP 7.4)
$obj = new stdClass();
$weakRef = WeakReference::create($obj);

// Preloading script would be in a separate file
// opcache_compile_file(__DIR__ . '/UserManager.php');
