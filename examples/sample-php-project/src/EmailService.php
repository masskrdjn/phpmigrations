<?php

/**
 * Exemple de service avec des patterns à moderniser
 */
class EmailService 
{
    private $mailer;
    private $templates;
    
    public function __construct() 
    {
        $this->mailer = null;
        $this->templates = array();
    }
    
    public function setMailer($mailer) 
    {
        $this->mailer = $mailer;
    }
    
    public function sendEmail($to, $subject, $body, $attachments = null) 
    {
        if ($this->mailer == null) {
            throw new Exception('Mailer not configured');
        }
        
        if ($to == null || $to == '') {
            return false;
        }
        
        if ($attachments != null) {
            foreach ($attachments as $attachment) {
                // Process attachments...
            }
        }
        
        return $this->mailer->send($to, $subject, $body);
    }
    
    public function addTemplate($name, $content) 
    {
        if ($name != null && $content != null) {
            $this->templates[$name] = $content;
        }
    }
    
    public function getTemplate($name) 
    {
        if (array_key_exists($name, $this->templates)) {
            return $this->templates[$name];
        } else {
            return null;
        }
    }
    
    public function renderTemplate($name, $variables = array()) 
    {
        $template = $this->getTemplate($name);
        
        if ($template == null) {
            return '';
        }
        
        foreach ($variables as $key => $value) {
            $template = str_replace('{{' . $key . '}}', $value, $template);
        }
        
        return $template;
    }
}
