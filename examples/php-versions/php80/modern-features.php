<?php

/**
 * PHP 8.0 Example Code
 * Features to be modernized:
 * - Union types
 * - Named arguments
 * - Attributes
 * - Constructor property promotion
 * - Match expressions
 * - Nullsafe operator
 * - str_contains, str_starts_with, str_ends_with
 */

declare(strict_types=1);

use JetBrains\PhpStorm\Pure;

// Attributes for metadata
#[Pure]
#[Deprecated('Use UserManagerV2 instead')]
class UserManager
{
    // Constructor property promotion
    public function __construct(
        private array $users = [],
        private ?PDO $connection = null,
        private string|int $cacheKey = 'users',  // Union types
        private int $maxUsers = 1000
    ) {}
    
    // Union types and named arguments
    public function addUser(
        string $name,
        string $email,
        int|float $age,  // Union type
        string $status = 'active'
    ): bool {
        if (count($this->users) >= $this->maxUsers) {
            throw new InvalidArgumentException('Maximum users limit reached');
        }
        
        $user = [
            'id' => uniqid(),
            'name' => $name,
            'email' => $email,
            'age' => (int) $age,
            'status' => $status,
            'created_at' => new DateTimeImmutable()
        ];
        
        $this->users[] = $user;
        return true;
    }
    
    // Match expression instead of switch
    public function getUserStatusLabel(string $status): string
    {
        return match($status) {
            'active' => 'Active User',
            'inactive' => 'Inactive User',
            'pending' => 'Pending Approval',
            'banned' => 'Banned User',
            default => 'Unknown Status'
        };
    }
    
    // Nullsafe operator
    public function getUserEmailDomain(string $userId): ?string
    {
        $user = $this->getUser($userId);
        return $user?->email ? explode('@', $user->email)[1] ?? null : null;
    }
    
    // Using new string functions
    public function validateEmail(string $email): bool
    {
        return str_contains($email, '@') 
            && !str_starts_with($email, '@')
            && !str_ends_with($email, '@');
    }
    
    public function getUser(string $id): ?object
    {
        foreach ($this->users as $user) {
            if ($user['id'] === $id) {
                return (object) $user;
            }
        }
        return null;
    }
    
    // Mixed type for flexible returns
    public function searchUsers(string $query): array|false
    {
        if (strlen($query) < 2) {
            return false;
        }
        
        return array_filter($this->users, function(array $user) use ($query): bool {
            return str_contains(strtolower($user['name']), strtolower($query))
                || str_contains(strtolower($user['email']), strtolower($query));
        });
    }
}

// Named arguments example
class EmailService
{
    public function __construct(
        private string $host,
        private int $port = 587,
        private string $encryption = 'tls',
        private ?string $username = null,
        private ?string $password = null
    ) {}
    
    public function sendEmail(
        string $to,
        string $subject,
        string $body,
        array $attachments = [],
        bool $isHtml = false,
        string $priority = 'normal'
    ): bool {
        // Email sending logic here
        return true;
    }
}

// Attributes for validation
#[Attribute]
class Validate
{
    public function __construct(
        public string $type,
        public ?int $min = null,
        public ?int $max = null
    ) {}
}

class User
{
    public function __construct(
        #[Validate('string', min: 2, max: 50)]
        public string $name,
        
        #[Validate('email')]
        public string $email,
        
        #[Validate('int', min: 13, max: 120)]
        public int $age
    ) {}
}

// Static return type
class MathUtils
{
    public static function add(int|float $a, int|float $b): int|float
    {
        return $a + $b;
    }
    
    public static function divide(int|float $a, int|float $b): int|float|false
    {
        return $b !== 0 ? $a / $b : false;
    }
}

// Usage with named arguments
$manager = new UserManager(
    maxUsers: 5000,
    cacheKey: 'production_users'
);

// Adding users with named arguments
$manager->addUser(
    name: 'Alice Johnson',
    email: 'alice@example.com',
    age: 28,
    status: 'active'
);

$manager->addUser(
    email: 'bob@company.org',  // Order doesn't matter with named arguments
    age: 35.5,  // Will be cast to int
    name: 'Bob Smith'
);

// Email service with named arguments
$emailService = new EmailService(
    host: 'smtp.gmail.com',
    port: 587,
    encryption: 'tls',
    username: 'user@gmail.com',
    password: 'password'
);

$emailService->sendEmail(
    to: 'recipient@example.com',
    subject: 'Welcome!',
    body: '<h1>Welcome to our service!</h1>',
    isHtml: true,
    priority: 'high'
);

// Match expression usage
$statusLabel = $manager->getUserStatusLabel('active');
echo "Status: {$statusLabel}\n";

// String function examples
$emails = [
    'valid@example.com',
    '@invalid.com',
    'invalid@',
    'another@valid.org'
];

foreach ($emails as $email) {
    $isValid = $manager->validateEmail($email);
    echo "Email {$email} is " . ($isValid ? 'valid' : 'invalid') . "\n";
}

// Math operations
echo "Addition: " . MathUtils::add(10, 20.5) . "\n";
echo "Division: " . MathUtils::divide(10, 3) . "\n";
