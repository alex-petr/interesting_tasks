<?php

/**
 * Init WordPress environment.
 */
require_once('../../wp-load.php');

/**
 * Constants of HTTP status codes. @link https://en.wikipedia.org/wiki/List_of_HTTP_status_codes
 */
// 2xx: Success
defined('STATUS_OK') or define('STATUS_OK', 200);
defined('STATUS_CREATED') or define('STATUS_CREATED', 201);
// 4xx: Client error
defined('STATUS_BAD_REQUEST') or define('STATUS_BAD_REQUEST', 400);
defined('STATUS_UNAUTHORIZED') or define('STATUS_UNAUTHORIZED', 401);
defined('STATUS_NOT_FOUND') or define('STATUS_NOT_FOUND', 404);
// 5xx: Server error
defined('STATUS_INTERNAL_SERVER_ERROR') or define('STATUS_INTERNAL_SERVER_ERROR', 500);

/**
 * @const string Path to API directory.
 */
// @todo: maybe move this to class consts section!!
defined('API_PATH') or define('API_PATH', dirname(__FILE__) . '/');
defined('API_LOG_FILE') or define('API_LOG_FILE', API_PATH . 'runtime.log');
/**
 * @const string Secret API keys file.
 */
defined('API_SECRETS_FILE') or define('API_SECRETS_FILE', API_PATH . 'secrets.php');

if (file_exists(API_SECRETS_FILE)) {
    require_once(API_SECRETS_FILE);
    define('API_SECRETS_ERROR', false);
} else {
    define('API_SECRETS_ERROR', true);
}

/**
 * Basic API class. Provide server response & logging methods.
 *
 * @author Alexander Petrov <petrov@wearepush.co>
 * @project ShopSmart Blog
 * @date 12/02/16 20:07
 * @link http://wearepush.co/
 * @copyright Copyright © 2016 Alexander Petrov
 */
class API
{
    /**
     * @var array Response statuses with messages.
     */
    private static $_response_messages = array(
        STATUS_OK => array('OK', 'Success.'),
        STATUS_CREATED => array('Created', 'Resource created.'),
        STATUS_BAD_REQUEST => array('Bad Request', 'Invalid request entity, unable to process.'),
        STATUS_UNAUTHORIZED => array('Unauthorized', 'You are not authorized to perform that action.'),
        STATUS_NOT_FOUND => array('Not Found', 'The resource you were looking for could not be found.'),
        STATUS_INTERNAL_SERVER_ERROR => array('Internal Server Error', 'Error during performing the request.'),
    );

    /**
     * @const string Logger message pattern.
     */
    const LOG_RECORD_PATTERN = '%{level_letter}, [%{date} #%{process_id}]  %{level_name} -- : ';

    /**
     * Get server IP.
     *
     * @return mixed
     */
    public static function get_server_ip()
    {
        return $_SERVER['SERVER_ADDR'];
    }

    /**
     * Get remote IP.
     *
     * @return mixed
     */
    public static function get_remote_ip()
    {
        // Check IP from share Internet.
        if (!empty($_SERVER['HTTP_X_REAL_IP'])) {
            $remote_ip = $_SERVER['HTTP_X_REAL_IP'];
            // Check IP from share Internet.
        } elseif (!empty($_SERVER['HTTP_CLIENT_IP'])) {
            $remote_ip = $_SERVER['HTTP_CLIENT_IP'];
            // Check if IP is pass from behind a proxy server.
        } elseif (!empty($_SERVER['HTTP_X_FORWARDED_FOR'])) {
            $remote_ip = $_SERVER['HTTP_X_FORWARDED_FOR'];
            // The IP address from which the user is viewing the current page.
        } else {
            $remote_ip = $_SERVER['REMOTE_ADDR'];
        }
        return $remote_ip;
    }

    /**
     * Compare IPs of server and machine that runs script.
     *
     * @return bool
     */
    public static function is_valid_ip()
    {
        return self::get_server_ip() === self::get_remote_ip();
    }

    /**
     * Compare two secret keys for equality.
     *
     * @param $secret
     * @return bool
     */
    public static function is_valid_secret($secret)
    {
        return defined('SECRET') && $secret == SECRET;
    }

    /**
     * Send HTTP response with code and message in JSON format.
     *
     * @param $status_code
     * @param null $response_data
     */
    public static function send_response($status_code, $response_data = null)
    {
        header("HTTP/1.1 {$status_code} " . self::$_response_messages[$status_code][0]);
        header('Content-Type: application/json; charset=UTF-8', true);
        if (399 < $status_code) {
            $response_data['success'] = false;
            $response_data['messages']['error'][] = self::$_response_messages[$status_code][1];
        }
        if (null != $response_data) {
            echo json_encode($response_data);
        }
        exit;
    }

    /**
     * Append message to log file.
     *
     * @param $level string Log level.
     * @param $data string Message to save.
     */
    public static function save_to_log($level, $data)
    {
        $record = $record_header = '';

        $record_header = str_replace(
            array(
                '%{level_letter}',
                '%{date}',
                '%{level_name}',
                '%{process_id}',
            ),
            array(
                $level[0],
                date("Y-m-d H:i:s {$_SERVER['REQUEST_TIME']}" /*'m/d/Y H:i:s'*//*DATE_ISO8601*/),
                $level,
                getmypid(),
            ),
            self::LOG_RECORD_PATTERN
        );
        $remote_ip = self::get_remote_ip();
        $record .= "{$record_header}Started {$_SERVER['REQUEST_METHOD']} \"{$_SERVER['REQUEST_URI']}\" for {$remote_ip}\n";
        $record .= "{$record_header}User Agent: {$_SERVER['HTTP_USER_AGENT']}\n";
        $record .= "{$record_header}{$data}\n\n";
        file_put_contents(API_LOG_FILE, $record, FILE_APPEND);
    }

    /**
     * Wrapper logger method for: self::debug(), self::info(), self::warn(), self::error(), self::fatal().
     *
     * @param $name
     * @param $arguments
     */
    public static function __callStatic($name, $arguments)
    {
        if (false !== strpos('debug|info|warn|error|fatal', $name)) {
            self::save_to_log(strtoupper($name), $arguments[0]);
        }
    }
}

if (API_SECRETS_ERROR) {
    API::send_response(
        STATUS_INTERNAL_SERVER_ERROR,
        array('messages' => array('error' => array('API secrets file not exists.')))
    );
}
