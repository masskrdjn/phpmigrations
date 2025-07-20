<?php

/**
 * PHP 8.2 Example Code
 * Features to be modernized:
 * - Readonly classes
 * - DNF (Disjunctive Normal Form) types
 * - Constants in traits
 * - Dynamic properties deprecation
 * - New random extension
 * - Sensitive parameter attribute
 */

declare(strict_types=1);

// Readonly classes
readonly class UserProfile
{
    public function __construct(
        public string $id,
        public string $firstName,
        public string $lastName,
        public string $email,
        public DateTimeImmutable $birthDate,
        public array $preferences = []
    ) {}
    
    public function getFullName(): string
    {
        return $this->firstName . ' ' . $this->lastName;
    }
    
    public function getAge(): int
    {
        return $this->birthDate->diff(new DateTimeImmutable())->y;
    }
    
    public function withPreference(string $key, mixed $value): self
    {
        $newPreferences = $this->preferences;
        $newPreferences[$key] = $value;
        
        return new self(
            $this->id,
            $this->firstName,
            $this->lastName,
            $this->email,
            $this->birthDate,
            $newPreferences
        );
    }
}

// DNF (Disjunctive Normal Form) types
interface Readable {
    public function read(): string;
}

interface Writable {
    public function write(string $data): bool;
}

interface Seekable {
    public function seek(int $position): bool;
}

class FileHandler
{
    // DNF type: (Readable&Writable)|(Readable&Seekable)
    public function processFile((Readable&Writable)|(Readable&Seekable) $file): string
    {
        $content = $file->read();
        
        if ($file instanceof Writable) {
            $file->write("Processed: " . $content);
        }
        
        if ($file instanceof Seekable) {
            $file->seek(0);
        }
        
        return $content;
    }
}

// Traits with constants
trait ApiResponseTrait
{
    public const SUCCESS_STATUS = 'success';
    public const ERROR_STATUS = 'error';
    public const WARNING_STATUS = 'warning';
    
    protected function formatResponse(string $status, mixed $data, ?string $message = null): array
    {
        return [
            'status' => $status,
            'data' => $data,
            'message' => $message,
            'timestamp' => time()
        ];
    }
    
    public function successResponse(mixed $data, ?string $message = null): array
    {
        return $this->formatResponse(self::SUCCESS_STATUS, $data, $message);
    }
    
    public function errorResponse(string $message, mixed $data = null): array
    {
        return $this->formatResponse(self::ERROR_STATUS, $data, $message);
    }
}

class UserApiController
{
    use ApiResponseTrait;
    
    public function __construct(
        private UserRepository $repository
    ) {}
    
    public function getUser(string $id): array
    {
        $user = $this->repository->findById($id);
        
        if (!$user) {
            return $this->errorResponse('User not found');
        }
        
        return $this->successResponse($user);
    }
}

class UserRepository
{
    private array $users = [];
    
    public function findById(string $id): ?UserProfile
    {
        return $this->users[$id] ?? null;
    }
    
    public function save(UserProfile $user): void
    {
        $this->users[$user->id] = $user;
    }
}

// Using new random extension
class TokenGenerator
{
    public function generateSecureToken(int $length = 32): string
    {
        return bin2hex(random_bytes($length / 2));
    }
    
    public function generateRandomId(): string
    {
        return sprintf(
            '%04x%04x-%04x-%04x-%04x-%04x%04x%04x',
            random_int(0, 0xffff),
            random_int(0, 0xffff),
            random_int(0, 0xffff),
            random_int(0, 0x0fff) | 0x4000,
            random_int(0, 0x3fff) | 0x8000,
            random_int(0, 0xffff),
            random_int(0, 0xffff),
            random_int(0, 0xffff)
        );
    }
    
    public function getRandomElement(array $array): mixed
    {
        if (empty($array)) {
            throw new InvalidArgumentException('Array cannot be empty');
        }
        
        return $array[array_rand($array)];
    }
}

// Sensitive parameter attribute for security
class AuthenticationService
{
    public function __construct(
        private string $secretKey
    ) {}
    
    // Mark sensitive parameters to avoid them in stack traces
    public function authenticateUser(
        string $username,
        #[SensitiveParameter] string $password
    ): bool {
        // In real implementation, this would hash and compare
        $hashedPassword = password_hash($password, PASSWORD_DEFAULT);
        
        // Simulate authentication logic
        return $this->validateCredentials($username, $hashedPassword);
    }
    
    private function validateCredentials(
        string $username,
        #[SensitiveParameter] string $hashedPassword
    ): bool {
        // Authentication logic here
        return true; // Simplified for example
    }
    
    public function generateJWT(
        array $payload,
        #[SensitiveParameter] string $secret
    ): string {
        // JWT generation logic
        $header = base64_encode(json_encode(['typ' => 'JWT', 'alg' => 'HS256']));
        $payload = base64_encode(json_encode($payload));
        $signature = hash_hmac('sha256', "$header.$payload", $secret, true);
        $signature = base64_encode($signature);
        
        return "$header.$payload.$signature";
    }
}

// File implementations for DNF types example
class ReadWriteFile implements Readable, Writable
{
    private string $content = '';
    
    public function read(): string
    {
        return $this->content;
    }
    
    public function write(string $data): bool
    {
        $this->content = $data;
        return true;
    }
}

class ReadSeekFile implements Readable, Seekable
{
    private string $content = 'Sample file content for seeking';
    private int $position = 0;
    
    public function read(): string
    {
        return substr($this->content, $this->position);
    }
    
    public function seek(int $position): bool
    {
        if ($position >= 0 && $position <= strlen($this->content)) {
            $this->position = $position;
            return true;
        }
        return false;
    }
}

// Usage examples

// Readonly class usage
$profile = new UserProfile(
    id: 'user123',
    firstName: 'John',
    lastName: 'Doe',
    email: 'john.doe@example.com',
    birthDate: new DateTimeImmutable('1990-05-15')
);

echo "User: " . $profile->getFullName() . " (Age: " . $profile->getAge() . ")\n";

// Modify readonly class (creates new instance)
$profileWithPrefs = $profile->withPreference('theme', 'dark')
                           ->withPreference('language', 'en');

// DNF types usage
$fileHandler = new FileHandler();

$rwFile = new ReadWriteFile();
$rsFile = new ReadSeekFile();

$content1 = $fileHandler->processFile($rwFile);
$content2 = $fileHandler->processFile($rsFile);

echo "Processed content 1: " . $content1 . "\n";
echo "Processed content 2: " . $content2 . "\n";

// API controller with traits
$repository = new UserRepository();
$repository->save($profile);

$controller = new UserApiController($repository);
$response = $controller->getUser('user123');

echo "API Response: " . json_encode($response, JSON_PRETTY_PRINT) . "\n";

// Token generation
$tokenGen = new TokenGenerator();
echo "Secure token: " . $tokenGen->generateSecureToken() . "\n";
echo "Random ID: " . $tokenGen->generateRandomId() . "\n";

$colors = ['red', 'green', 'blue', 'yellow', 'purple'];
echo "Random color: " . $tokenGen->getRandomElement($colors) . "\n";

// Authentication with sensitive parameters
$auth = new AuthenticationService('my-secret-key');
$isValid = $auth->authenticateUser('john_doe', 'super_secret_password');

$jwt = $auth->generateJWT([
    'user_id' => 'user123',
    'username' => 'john_doe',
    'exp' => time() + 3600
], 'jwt-secret-key');

echo "Authentication successful: " . ($isValid ? 'Yes' : 'No') . "\n";
echo "JWT Token: " . substr($jwt, 0, 50) . "...\n";

// Demonstrate constant usage from trait
echo "Success status: " . UserApiController::SUCCESS_STATUS . "\n";
echo "Error status: " . UserApiController::ERROR_STATUS . "\n";
