import os
import boto3

def _s3_client():
    # Читаем все параметры из переменных окружения
    access_key = os.getenv("AWS_ACCESS_KEY_ID", "")
    secret_key = os.getenv("AWS_SECRET_ACCESS_KEY", "")
    region = os.getenv("AWS_REGION", "ru-central1")
    endpoint = os.getenv("AWS_S3_ENDPOINT", "https://storage.yandexcloud.net")
    force_path_style = os.getenv("AWS_S3_FORCE_PATH_STYLE", "true").lower() == "true"

    session = boto3.session.Session()
    return session.client(
        service_name="s3",
        region_name=region,
        endpoint_url=endpoint,
        aws_access_key_id=access_key,
        aws_secret_access_key=secret_key,
        config=boto3.session.Config(s3={"addressing_style": "path" if force_path_style else "auto"})
    )

def upload_report():
    """
    Пример: загрузка заранее сгенерированного файла или буфера в бакет.
    """
    bucket = os.getenv("AWS_BUCKET_NAME", "")
    if not bucket:
        raise RuntimeError("AWS_BUCKET_NAME is not set")

    s3 = _s3_client()
    key = "reports/example.txt"
    s3.put_object(Bucket=bucket, Key=key, Body=b"hello from yandex object storage")
    return key
