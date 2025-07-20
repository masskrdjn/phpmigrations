<?php

/**
 * PHP 8.1 Example Code
 * Features to be modernized:
 * - Enums
 * - Readonly properties
 * - Fibers
 * - Intersection types
 * - First-class callable syntax
 * - New in_array() variant
 * - Final class constants
 */

declare(strict_types=1);

// Enums for better type safety
enum UserStatus: string
{
    case ACTIVE = 'active';
    case INACTIVE = 'inactive';
    case PENDING = 'pending';
    case BANNED = 'banned';
    
    public function getLabel(): string
    {
        return match($this) {
            self::ACTIVE => 'Active User',
            self::INACTIVE => 'Inactive User',
            self::PENDING => 'Pending Approval',
            self::BANNED => 'Banned User',
        };
    }
    
    public function canLogin(): bool
    {
        return $this === self::ACTIVE;
    }
}

enum Permission: int
{
    case READ = 1;
    case WRITE = 2;
    case DELETE = 4;
    case ADMIN = 8;
    
    public function hasPermission(int $userPermissions): bool
    {
        return ($userPermissions & $this->value) === $this->value;
    }
}

// Readonly properties
class User
{
    public function __construct(
        public readonly string $id,
        public readonly string $name,
        public readonly string $email,
        public UserStatus $status = UserStatus::PENDING,
        public readonly DateTimeImmutable $createdAt = new DateTimeImmutable()
    ) {}
    
    public function activate(): self
    {
        // Since properties are readonly, we need to create a new instance
        return new self(
            $this->id,
            $this->name,
            $this->email,
            UserStatus::ACTIVE,
            $this->createdAt
        );
    }
    
    public function ban(): self
    {
        return new self(
            $this->id,
            $this->name,
            $this->email,
            UserStatus::BANNED,
            $this->createdAt
        );
    }
}

// Intersection types
interface Loggable
{
    public function log(string $message): void;
}

interface Cacheable
{
    public function getCacheKey(): string;
    public function getCacheTtl(): int;
}

class UserRepository
{
    public function __construct(
        private array $users = []
    ) {}
    
    // Intersection type: must implement both interfaces
    public function setLogger(Loggable&Cacheable $service): void
    {
        $service->log('UserRepository logger set');
        // Can also use cache methods
        $cacheKey = $service->getCacheKey();
    }
    
    public function addUser(User $user): void
    {
        $this->users[$user->id] = $user;
    }
    
    public function findByStatus(UserStatus $status): array
    {
        return array_filter(
            $this->users,
            fn(User $user): bool => $user->status === $status
        );
    }
    
    // First-class callable syntax
    public function getUserNames(): array
    {
        return array_map(
            fn(User $user): string => $user->name,
            $this->users
        );
    }
    
    // Using array_is_list() for better array type checking
    public function processUserData(array $data): array
    {
        if (!array_is_list($data)) {
            throw new InvalidArgumentException('Expected list of users');
        }
        
        return array_map(
            fn(array $userData): User => new User(
                $userData['id'],
                $userData['name'],
                $userData['email']
            ),
            $data
        );
    }
}

// Final class constants
class ApiConfig
{
    final public const VERSION = '2.1';
    final public const MAX_REQUESTS_PER_MINUTE = 60;
    
    private const ENDPOINTS = [
        'users' => '/api/users',
        'auth' => '/api/auth',
        'profile' => '/api/profile'
    ];
    
    public static function getEndpoint(string $name): string
    {
        return self::ENDPOINTS[$name] ?? throw new InvalidArgumentException("Unknown endpoint: {$name}");
    }
}

// Fibers for async operations
class AsyncUserProcessor
{
    private array $fibers = [];
    
    public function processUserAsync(User $user, callable $processor): Fiber
    {
        $fiber = new Fiber(function() use ($user, $processor) {
            // Simulate async work
            Fiber::suspend();
            return $processor($user);
        });
        
        $this->fibers[] = $fiber;
        return $fiber;
    }
    
    public function runAllFibers(): array
    {
        $results = [];
        
        foreach ($this->fibers as $fiber) {
            $fiber->start();
            
            // Resume the fiber
            if ($fiber->isSuspended()) {
                $results[] = $fiber->resume();
            }
        }
        
        return $results;
    }
}

// Service that implements both interfaces for intersection type example
class LoggingCacheService implements Loggable, Cacheable
{
    public function log(string $message): void
    {
        error_log($message);
    }
    
    public function getCacheKey(): string
    {
        return 'user_repository_' . date('Y-m-d');
    }
    
    public function getCacheTtl(): int
    {
        return 3600; // 1 hour
    }
}

// Usage examples
$repository = new UserRepository();

// Create users with enums
$user1 = new User('user1', 'Alice Johnson', 'alice@example.com');
$user2 = new User('user2', 'Bob Smith', 'bob@example.com');

$repository->addUser($user1);
$repository->addUser($user2);

// Activate pending user
$activatedUser2 = $user2->activate();
$repository->addUser($activatedUser2);

// Find users by status
$activeUsers = $repository->findByStatus(UserStatus::ACTIVE);
echo "Active users: " . count($activeUsers) . "\n";

// Check permissions
$userPermissions = Permission::READ->value | Permission::WRITE->value;
echo "Can read: " . (Permission::READ->hasPermission($userPermissions) ? 'Yes' : 'No') . "\n";
echo "Can delete: " . (Permission::DELETE->hasPermission($userPermissions) ? 'Yes' : 'No') . "\n";

// Use intersection type
$loggingService = new LoggingCacheService();
$repository->setLogger($loggingService);

// Process user data from array
$userData = [
    ['id' => 'user3', 'name' => 'Charlie Brown', 'email' => 'charlie@example.com', 'status' => 'active'],
    ['id' => 'user4', 'name' => 'Diana Prince', 'email' => 'diana@example.com', 'status' => 'pending']
];

$processedUsers = $repository->processUserData($userData);
foreach ($processedUsers as $user) {
    $repository->addUser($user);
    echo "Processed user: {$user->name} ({$user->status->getLabel()})\n";
}

// Async processing example
$asyncProcessor = new AsyncUserProcessor();

foreach ($repository->findByStatus(UserStatus::ACTIVE) as $user) {
    $asyncProcessor->processUserAsync($user, function(User $user): string {
        // Simulate some processing
        return "Processed: {$user->name}";
    });
}

$results = $asyncProcessor->runAllFibers();
foreach ($results as $result) {
    echo $result . "\n";
}

// API configuration
echo "API Version: " . ApiConfig::VERSION . "\n";
echo "Users endpoint: " . ApiConfig::getEndpoint('users') . "\n";
