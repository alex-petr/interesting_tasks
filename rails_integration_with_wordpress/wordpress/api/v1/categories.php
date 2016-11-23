<?php

require_once('api.php');

/**
 * @const string ShopSmart categories API URL.
 */
defined('URL_SHOPSMART_CATEGORIES_API') or define('URL_SHOPSMART_CATEGORIES_API', SHOPSMART_DOMAIN . '/api/v1/categories.json');

/**
 * Categories API class. Provide different actions with categories.
 *
 * @author Alexander Petrov <petrov@wearepush.co>
 * @project ShopSmart Blog
 * @date 12/02/16 17:54
 * @link http://wearepush.co/
 * @copyright Copyright © 2016 Alexander Petrov
 */
final class Categories extends API
{
    /**
     * @const string Cache expiration time in hours.
     */
    const CACHE_EXPIRATION = 1;

    /**
     * @const string Cache storage key name.
     */
    const CACHE_STORAGE_KEY = 'categories';

    /**
     * Fetch categories from ShopSmart categories API.
     *
     * @return false|string
     */
    private static function fetch()
    {
        $result = array('success' => false, 'data' => null);
        if (ini_get('allow_url_fopen')) {
            $data = @file_get_contents(URL_SHOPSMART_CATEGORIES_API);
            if (false !== $data) {
                $result = array('success' => true, 'data' => $data);
            } else {
                $result['data'] = 'file_get_contents() failed to fetch ' . URL_SHOPSMART_CATEGORIES_API;
            }
        } else if (function_exists('curl_init')) {
            $curl_handle = curl_init(URL_SHOPSMART_CATEGORIES_API);
            curl_setopt($curl_handle, CURLOPT_RETURNTRANSFER, 1);
            $data = curl_exec($curl_handle);
            if ($data) {
                $result = array('success' => true, 'data' => $data);
            } else {
                $result['data'] = 'curl_exec() failed to fetch ' . URL_SHOPSMART_CATEGORIES_API . ' '
                    . curl_error($curl_handle);
            }
            curl_close($curl_handle);
        }
        return $result;
    }

    /**
     * Update categories cache.
     * return updated = boolean
     */
    public static function update()
    {
        $result = array('success' => false, 'level' => 'fatal', 'message' => null);
        if (false === ($cache_data = get_transient(self::CACHE_STORAGE_KEY))) {
            $fetch_result = self::fetch();
            if ($fetch_result['success']) {
                $cache_data = $fetch_result['data'];
                $result['message'] = 'Category data fetched. ';
                if (set_transient(self::CACHE_STORAGE_KEY, $cache_data, self::CACHE_EXPIRATION * HOUR_IN_SECONDS)) {
                    $result['success'] = true;
                    $result['message'] .= 'Category data saved to DB.';
                } else {
                    $result['message'] .= 'Error during saving category data to DB in set_transient().';
                }
            } else {
                $result['message'] .= 'Error during fetching category data: ' . $fetch_result['data'];
            }
        } else {
            $result = array('success' => false, 'level' => 'info', 'message' => 'Cache not expired yet.');
        }
        return $result;
    }
}

$response = array('status' => STATUS_UNAUTHORIZED, 'data' => null);

if (isset($_GET['secret']) && Categories::is_valid_secret($_GET['secret'])) {
    if (Categories::is_valid_ip()) {
        if(isset($_GET['action']) && 'update' == $_GET['action']) {
            $update_result = Categories::update();
            if ($update_result['success']) {
                Categories::info($update_result['message']);
                $response = array(
                    'status' => STATUS_OK,
                    'data'   => array(
                        'success' => true,
                        'messages' => array(
                            'success' => array($update_result['message']),
                        )
                    )
                );
            } else {
                if ('info' == $update_result['level']) {
                    Categories::info($update_result['message']);
                } else {
                    Categories::fatal($update_result['message']);
                }
                $response = array(
                    'status' => STATUS_INTERNAL_SERVER_ERROR,
                    'data'   => array(
                        'messages' => array(
                            'error' => array($update_result['message']),
                        )
                    )
                );
            }
        } else {
            $message = 'Invalid action.';
            Categories::warn($message);
            $response['data'] = array('messages' => array('error' => array($message)));
        }
    } else {
        $message = 'Invalid remote IP.';
        Categories::warn($message);
        $response['data'] = array('messages' => array('error' => array($message)));
    }
} else {
    $message = 'Invalid secret key.';
    Categories::warn($message);
    $response['data'] = array('messages' => array('error' => array($message)));
}

Categories::send_response($response['status'], $response['data']);
