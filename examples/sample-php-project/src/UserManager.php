<?php

/**
 * Exemple de classe PHP à moderniser
 * Ce code utilise des patterns anciens que Rector peut améliorer
 */
class UserManager 
{
    private $users;
    private $config;
    
    public function __construct($config = null) 
    {
        $this->users = array();
        $this->config = $config;
    }
    
    public function addUser($name, $email = null) 
    {
        if ($name != null && $name != '') {
            $user = array(
                'name' => $name, 
                'email' => $email,
                'created_at' => date('Y-m-d H:i:s')
            );
            array_push($this->users, $user);
            return true;
        }
        return false;
    }
    
    public function getUserById($id) 
    {
        foreach ($this->users as $user) {
            if ($user['id'] == $id) {
                return $user;
            }
        }
        return null;
    }
    
    public function getUsers() 
    {
        return $this->users;
    }
    
    public function getUserCount() 
    {
        return count($this->users);
    }
    
    public function validateEmail($email) 
    {
        if ($email == null) {
            return false;
        }
        
        if (filter_var($email, FILTER_VALIDATE_EMAIL)) {
            return true;
        } else {
            return false;
        }
    }
    
    public function processUsers($callback) 
    {
        if ($callback != null) {
            call_user_func_array($callback, array($this->users));
        }
    }
    
    public function exportUsers($format = 'json') 
    {
        switch ($format) {
            case 'json':
                return json_encode($this->users);
                break;
            case 'csv':
                // Implémentation CSV...
                return '';
                break;
            default:
                return '';
        }
    }
}
