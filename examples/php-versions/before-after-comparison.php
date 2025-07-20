<?php

/**
 * Complete Migration Example - Before & After
 * This file shows the same functionality implemented in different PHP versions
 * to demonstrate the power of Rector migrations
 */

// ==================================================
// PHP 5.6 LEGACY VERSION (BEFORE MIGRATION)
// ==================================================

class LegacyUserManager_PHP56
{
    private $users;
    private $config;
    
    public function __construct($config)
    {
        $this->users = array();
        $this->config = $config;
    }
    
    public function addUser($name, $email, $age, $permissions)
    {
        $user = array(
            'id' => uniqid(),
            'name' => $name,
            'email' => $email,
            'age' => $age,
            'permissions' => $permissions,
            'status' => 'active',
            'created_at' => date('Y-m-d H:i:s')
        );
        
        array_push($this->users, $user);
        return true;
    }
    
    public function findUserByEmail($email)
    {
        foreach ($this->users as $user) {
            if ($user['email'] == $email) {
                return $user;
            }
        }
        return null;
    }
    
    public function getUsersByPermission($permission)
    {
        $result = array();
        foreach ($this->users as $user) {
            if (in_array($permission, $user['permissions'])) {
                $result[] = $user;
            }
        }
        return $result;
    }
    
    public function formatUserInfo($user)
    {
        $name = isset($user['name']) ? $user['name'] : 'Unknown';
        $email = isset($user['email']) ? $user['email'] : 'No email';
        $age = isset($user['age']) ? $user['age'] : 'Unknown';
        
        return "User: " . $name . " (" . $email . ") - Age: " . $age;
    }
    
    public function calculatePermissionLevel($permissions)
    {
        $level = 0;
        foreach ($permissions as $permission) {
            switch ($permission) {
                case 'read':
                    $level += 1;
                    break;
                case 'write':
                    $level += 2;
                    break;
                case 'delete':
                    $level += 4;
                    break;
                case 'admin':
                    $level += 8;
                    break;
            }
        }
        return $level;
    }
}

// ==================================================
// PHP 8.4 MODERN VERSION (AFTER MIGRATION)
// ==================================================

declare(strict_types=1);

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
}

enum Permission: int
{
    case READ = 1;
    case WRITE = 2;
    case DELETE = 4;
    case ADMIN = 8;
    
    public function getLabel(): string
    {
        return match($this) {
            self::READ => 'Read Access',
            self::WRITE => 'Write Access',
            self::DELETE => 'Delete Access',
            self::ADMIN => 'Admin Access',
        };
    }
}

readonly class User
{
    public function __construct(
        public string $id,
        public string $name,
        public string $email,
        public int $age,
        public array $permissions,
        public UserStatus $status = UserStatus::ACTIVE,
        public DateTimeImmutable $createdAt = new DateTimeImmutable()
    ) {}
    
    public string $displayInfo {
        get => "User: {$this->name} ({$this->email}) - Age: {$this->age}";
    }
    
    public int $permissionLevel {
        get => array_reduce(
            $this->permissions,
            fn(int $carry, Permission $permission): int => $carry | $permission->value,
            0
        );
    }
    
    public function hasPermission(Permission $permission): bool
    {
        return in_array($permission, $this->permissions, true);
    }
    
    public function withStatus(UserStatus $status): self
    {
        return new self(
            $this->id,
            $this->name, 
            $this->email,
            $this->age,
            $this->permissions,
            $status,
            $this->createdAt
        );
    }
}

class ModernUserManager_PHP84
{
    public function __construct(
        private array $users = [],
        private readonly array $config = []
    ) {}
    
    public function addUser(
        string $name,
        string $email,
        int $age,
        array $permissions
    ): bool {
        $permissionObjects = array_map(
            fn(Permission $perm): Permission => $perm,
            $permissions
        );
        
        $user = new User(
            uniqid(),
            $name,
            $email, 
            $age,
            $permissionObjects
        );
        
        $this->users[] = $user;
        return true;
    }
    
    public function findUserByEmail(string $email): ?User
    {
        return array_find(
            $this->users,
            fn(User $user): bool => $user->email === $email
        );
    }
    
    public function getUsersByPermission(Permission $permission): array
    {
        return array_filter(
            $this->users,
            fn(User $user): bool => $user->hasPermission($permission)
        );
    }
    
    public function getAllUsers(): array
    {
        return $this->users;
    }
    
    public function hasUsersWithPermission(Permission $permission): bool
    {
        return array_any(
            $this->users,
            fn(User $user): bool => $user->hasPermission($permission)
        );
    }
    
    public function areAllUsersActive(): bool
    {
        return array_all(
            $this->users,
            fn(User $user): bool => $user->status === UserStatus::ACTIVE
        );
    }
}

// ==================================================
// USAGE COMPARISON
// ==================================================

echo "=== Migration Example: PHP 5.6 → PHP 8.4 ===\n\n";

// PHP 5.6 Legacy usage
echo "🕰️  PHP 5.6 Legacy Implementation:\n";
$legacyManager = new LegacyUserManager_PHP56(['debug' => true]);
$legacyManager->addUser('John Doe', 'john@example.com', 30, ['read', 'write']);
$legacyManager->addUser('Jane Smith', 'jane@example.com', 25, ['read', 'write', 'admin']);

$legacyUser = $legacyManager->findUserByEmail('john@example.com');
if ($legacyUser) {
    echo "Found: " . $legacyManager->formatUserInfo($legacyUser) . "\n";
    echo "Permission level: " . $legacyManager->calculatePermissionLevel($legacyUser['permissions']) . "\n";
}

$legacyAdmins = $legacyManager->getUsersByPermission('admin');
echo "Admin users: " . count($legacyAdmins) . "\n\n";

// PHP 8.4 Modern usage  
echo "🚀 PHP 8.4 Modern Implementation:\n";
$modernManager = new ModernUserManager_PHP84(config: ['debug' => true]);
$modernManager->addUser('John Doe', 'john@example.com', 30, [Permission::READ, Permission::WRITE]);
$modernManager->addUser('Jane Smith', 'jane@example.com', 25, [Permission::READ, Permission::WRITE, Permission::ADMIN]);

$modernUser = $modernManager->findUserByEmail('john@example.com');
if ($modernUser) {
    echo "Found: " . $modernUser->displayInfo . "\n";
    echo "Permission level: " . $modernUser->permissionLevel . "\n";
    echo "Status: " . $modernUser->status->getLabel() . "\n";
}

$modernAdmins = $modernManager->getUsersByPermission(Permission::ADMIN);
echo "Admin users: " . count($modernAdmins) . "\n";

echo "Has admin users: " . ($modernManager->hasUsersWithPermission(Permission::ADMIN) ? 'Yes' : 'No') . "\n";
echo "All users active: " . ($modernManager->areAllUsersActive() ? 'Yes' : 'No') . "\n\n";

echo "✨ Migration Benefits:\n";
echo "  ✅ Type safety with enums and strict types\n";
echo "  ✅ Immutable objects with readonly properties\n"; 
echo "  ✅ Property hooks for computed values\n";
echo "  ✅ Modern array functions (array_find, array_any, array_all)\n";
echo "  ✅ Match expressions instead of switch statements\n";
echo "  ✅ Constructor property promotion\n";
echo "  ✅ Named arguments for better readability\n";
echo "  ✅ Arrow functions for concise code\n";
echo "  ✅ Null coalescing and other modern operators\n";
echo "  ✅ Better error handling and debugging\n";
