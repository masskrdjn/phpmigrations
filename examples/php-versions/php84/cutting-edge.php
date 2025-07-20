<?php

/**
 * PHP 8.4 Example Code
 * Latest features to test:
 * - Property hooks (get/set)
 * - Asymmetric visibility
 * - Array find functions
 * - New multibyte string functions
 * - Lazy objects
 * - Performance improvements
 */

declare(strict_types=1);

// Property hooks for computed properties
class Temperature
{
    public function __construct(
        public float $celsius = 0.0
    ) {}
    
    // Property hooks with get/set
    public float $fahrenheit {
        get => $this->celsius * 9/5 + 32;
        set => $this->celsius = ($value - 32) * 5/9;
    }
    
    public float $kelvin {
        get => $this->celsius + 273.15;
        set => $this->celsius = $value - 273.15;
    }
    
    // Read-only computed property
    public string $description {
        get => match(true) {
            $this->celsius < 0 => 'Freezing',
            $this->celsius < 10 => 'Cold',
            $this->celsius < 25 => 'Cool',
            $this->celsius < 35 => 'Warm',
            default => 'Hot'
        };
    }
}

// Asymmetric visibility (different visibility for read/write)
class BankAccount
{
    public function __construct(
        private string $accountNumber,
        private float $balance = 0.0,
        public private(set) string $status = 'active' // Public read, private write
    ) {}
    
    public private(set) float $availableBalance {
        get => $this->status === 'active' ? $this->balance : 0.0;
    }
    
    public function deposit(float $amount): void
    {
        if ($amount <= 0) {
            throw new InvalidArgumentException('Amount must be positive');
        }
        
        $this->balance += $amount;
    }
    
    public function withdraw(float $amount): bool
    {
        if ($amount <= 0 || $amount > $this->availableBalance) {
            return false;
        }
        
        $this->balance -= $amount;
        return true;
    }
    
    public function freeze(): void
    {
        $this->status = 'frozen';
    }
    
    public function activate(): void
    {
        $this->status = 'active';
    }
}

// Using new array find functions
class UserService
{
    private array $users = [];
    
    public function addUser(array $user): void
    {
        $this->users[] = $user;
    }
    
    // Using array_find (PHP 8.4)
    public function findUserByEmail(string $email): ?array
    {
        return array_find(
            $this->users,
            fn(array $user): bool => $user['email'] === $email
        );
    }
    
    // Using array_find_key (PHP 8.4)
    public function findUserKeyByEmail(string $email): int|string|null
    {
        return array_find_key(
            $this->users,
            fn(array $user): bool => $user['email'] === $email
        );
    }
    
    // Using array_any (PHP 8.4)
    public function hasAdminUser(): bool
    {
        return array_any(
            $this->users,
            fn(array $user): bool => $user['role'] === 'admin'
        );
    }
    
    // Using array_all (PHP 8.4)
    public function allUsersActive(): bool
    {
        return array_all(
            $this->users,
            fn(array $user): bool => $user['status'] === 'active'
        );
    }
}

// Lazy objects for performance
class ExpensiveResource
{
    private string $data;
    
    public function __construct()
    {
        // Simulate expensive initialization
        echo "Expensive resource initialized\n";
        $this->data = "Expensive data: " . str_repeat('X', 1000);
    }
    
    public function getData(): string
    {
        return $this->data;
    }
    
    public function processData(): string
    {
        return strtoupper($this->data);
    }
}

class LazyResourceContainer
{
    private ?ExpensiveResource $resource = null;
    
    // Lazy initialization
    public function getResource(): ExpensiveResource
    {
        return $this->resource ??= new ExpensiveResource();
    }
}

// Enhanced multibyte string handling
class TextProcessor
{
    public function processText(string $text): array
    {
        return [
            'length' => mb_strlen($text),
            'uppercase' => mb_strtoupper($text),
            'lowercase' => mb_strtolower($text),
            'title_case' => mb_convert_case($text, MB_CASE_TITLE),
            'word_count' => str_word_count($text),
            'char_frequency' => array_count_values(mb_str_split($text))
        ];
    }
    
    public function extractEmails(string $text): array
    {
        preg_match_all('/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/', $text, $matches);
        return $matches[0];
    }
    
    public function sanitizeText(string $text): string
    {
        // Remove special characters but keep international characters
        return preg_replace('/[^\p{L}\p{N}\s\-_.@]/u', '', $text);
    }
}

// Advanced enum with backed values and methods
enum HttpStatus: int
{
    case OK = 200;
    case CREATED = 201;
    case BAD_REQUEST = 400;
    case UNAUTHORIZED = 401;
    case FORBIDDEN = 403;
    case NOT_FOUND = 404;
    case INTERNAL_SERVER_ERROR = 500;
    
    public function getMessage(): string
    {
        return match($this) {
            self::OK => 'Request successful',
            self::CREATED => 'Resource created successfully',
            self::BAD_REQUEST => 'Invalid request parameters',
            self::UNAUTHORIZED => 'Authentication required',
            self::FORBIDDEN => 'Access denied',
            self::NOT_FOUND => 'Resource not found',
            self::INTERNAL_SERVER_ERROR => 'Server error occurred',
        };
    }
    
    public function isSuccess(): bool
    {
        return $this->value >= 200 && $this->value < 300;
    }
    
    public function isError(): bool
    {
        return $this->value >= 400;
    }
}

// API response with property hooks
class ApiResponse
{
    public function __construct(
        private array $data = [],
        private HttpStatus $status = HttpStatus::OK,
        private ?string $message = null
    ) {}
    
    // Computed property for response body
    public array $response {
        get => [
            'status' => $this->status->value,
            'message' => $this->message ?? $this->status->getMessage(),
            'data' => $this->data,
            'success' => $this->status->isSuccess(),
            'timestamp' => date('c')
        ];
    }
    
    // Property with validation
    public HttpStatus $httpStatus {
        get => $this->status;
        set {
            if ($value->isError() && empty($this->message)) {
                $this->message = $value->getMessage();
            }
            $this->status = $value;
        }
    }
}

// Usage examples

echo "=== PHP 8.4 Features Demo ===\n\n";

// Temperature with property hooks
echo "1. Property Hooks:\n";
$temp = new Temperature();
$temp->fahrenheit = 68; // Sets celsius via property hook
echo "68°F = {$temp->celsius}°C = {$temp->kelvin}K ({$temp->description})\n";

$temp->celsius = 100;
echo "100°C = {$temp->fahrenheit}°F = {$temp->kelvin}K ({$temp->description})\n\n";

// Bank account with asymmetric visibility
echo "2. Asymmetric Visibility:\n";
$account = new BankAccount('ACC123');
$account->deposit(1000);
echo "Balance: {$account->availableBalance} (Status: {$account->status})\n";

$account->freeze();
echo "After freeze - Available: {$account->availableBalance} (Status: {$account->status})\n";

$account->activate();
$account->withdraw(200);
echo "After withdrawal - Available: {$account->availableBalance}\n\n";

// Array find functions
echo "3. Array Find Functions:\n";
$userService = new UserService();
$userService->addUser(['id' => 1, 'name' => 'Alice', 'email' => 'alice@example.com', 'role' => 'user', 'status' => 'active']);
$userService->addUser(['id' => 2, 'name' => 'Bob', 'email' => 'bob@example.com', 'role' => 'admin', 'status' => 'active']);
$userService->addUser(['id' => 3, 'name' => 'Charlie', 'email' => 'charlie@example.com', 'role' => 'user', 'status' => 'inactive']);

$user = $userService->findUserByEmail('bob@example.com');
echo "Found user: " . ($user ? $user['name'] : 'None') . "\n";
echo "Has admin: " . ($userService->hasAdminUser() ? 'Yes' : 'No') . "\n";
echo "All active: " . ($userService->allUsersActive() ? 'Yes' : 'No') . "\n\n";

// Lazy objects
echo "4. Lazy Initialization:\n";
$container = new LazyResourceContainer();
echo "Container created (resource not yet initialized)\n";
$resource = $container->getResource(); // Now it initializes
echo "Resource data length: " . strlen($resource->getData()) . "\n\n";

// Text processing
echo "5. Text Processing:\n";
$processor = new TextProcessor();
$text = "Hello World! Contact us at info@example.com or support@test.org";
$result = $processor->processText($text);
echo "Text analysis: " . json_encode($result, JSON_PRETTY_PRINT) . "\n";

$emails = $processor->extractEmails($text);
echo "Extracted emails: " . implode(', ', $emails) . "\n\n";

// HTTP status and API response
echo "6. Enhanced Enums and API Response:\n";
$response = new ApiResponse(['users' => ['Alice', 'Bob']], HttpStatus::OK);
echo "Success response: " . json_encode($response->response, JSON_PRETTY_PRINT) . "\n";

$errorResponse = new ApiResponse([], HttpStatus::NOT_FOUND);
echo "Error response: " . json_encode($errorResponse->response, JSON_PRETTY_PRINT) . "\n";
