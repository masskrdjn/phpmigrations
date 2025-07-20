<?php

/**
 * PHP 5.6 Example Code for testing migration
 */

// Old array syntax
$users = array(
    array('name' => 'John', 'age' => 25),
    array('name' => 'Jane', 'age' => 30)
);

// Variable arguments (old way)
function calculateSum()
{
    $args = func_get_args();
    $sum = 0;
    foreach ($args as $arg) {
        $sum += $arg;
    }
    return $sum;
}

// Class without type hints
class UserManager
{
    const STATUS_ACTIVE = 'active';
    
    private $users;
    
    public function __construct()
    {
        $this->users = array();
    }
    
    public function addUser($name, $email)
    {
        $user = array(
            'name' => $name,
            'email' => $email,
            'status' => self::STATUS_ACTIVE
        );
        
        array_push($this->users, $user);
        return true;
    }
    
    public function getUser($id)
    {
        if (isset($this->users[$id])) {
            return $this->users[$id];
        }
        return null;
    }
}

// Usage
$manager = new UserManager();
$manager->addUser('Alice', 'alice@example.com');
echo "Sum: " . calculateSum(1, 2, 3, 4, 5);
